const express = require('express');
const {
  toPublicPart,
  toCompatibilityPart,
  toOwnerPart,
} = require('../services/marketplace/partPrivacy');

function createPartsRouter({
  db,
  verifyToken,
  marketplaceReadLimiter,
  marketplaceWriteLimiter,
  contactUidDailyLimiter,
  contactIpDailyLimiter,
  localizedError,
  logger,
  exposePublicContact = false,
}) {
  const router = express.Router();

  async function readParts() {
    const snapshot = await db.collection('parts').orderBy('createdAt', 'desc').get();
    return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  }

  // Named routes stay before any future /parts/:id GET route.
  router.get('/parts/mine', verifyToken, marketplaceReadLimiter, async (req, res) => {
    try {
      const snapshot = await db.collection('parts').where('ownerId', '==', req.uid).get();
      const parts = snapshot.docs
        .map((doc) => toOwnerPart(doc.id, doc.data()))
        .sort((a, b) => String(b.createdAt || '').localeCompare(String(a.createdAt || '')));
      res.json(parts);
    } catch (error) {
      logger.error('Failed to read seller listings', error, { requestId: req.requestId });
      res.status(500).json(localizedError(req, 'INTERNAL_ERROR'));
    }
  });

  router.get(
    '/parts/:id/contact',
    verifyToken,
    contactUidDailyLimiter,
    contactIpDailyLimiter,
    async (req, res) => {
      try {
        const doc = await db.collection('parts').doc(req.params.id).get();
        if (!doc.exists) {
          return res.status(404).json(localizedError(req, 'PART_NOT_FOUND'));
        }
        const sellerPhone = doc.data().sellerPhone;
        if (typeof sellerPhone !== 'string' || !sellerPhone.trim()) {
          return res.status(404).json(localizedError(req, 'PART_CONTACT_UNAVAILABLE'));
        }
        return res.json({ sellerPhone });
      } catch (error) {
        logger.error('Failed to retrieve seller contact', error, {
          requestId: req.requestId,
          partId: req.params.id,
        });
        return res.status(500).json(localizedError(req, 'INTERNAL_ERROR'));
      }
    },
  );

  router.get('/parts/:id/private', verifyToken, marketplaceReadLimiter, async (req, res) => {
    try {
      const doc = await db.collection('parts').doc(req.params.id).get();
      if (!doc.exists) {
        return res.status(404).json(localizedError(req, 'PART_NOT_FOUND'));
      }
      const part = doc.data();
      if (part.ownerId !== req.uid) {
        return res.status(403).json(localizedError(req, 'PART_READ_FORBIDDEN'));
      }
      return res.json(toOwnerPart(doc.id, part));
    } catch (error) {
      logger.error('Failed to read private seller listing', error, {
        requestId: req.requestId,
        partId: req.params.id,
      });
      return res.status(500).json(localizedError(req, 'INTERNAL_ERROR'));
    }
  });

  router.get('/parts', marketplaceReadLimiter, async (req, res) => {
    try {
      const { brand, model } = req.query;
      let parts = await readParts();
      if (brand) parts = parts.filter((part) => part.carBrand === brand);
      if (model) {
        parts = parts.filter(
          (part) => part.carModel && part.carModel.includes(model),
        );
      }
      const presenter = exposePublicContact ? toCompatibilityPart : toPublicPart;
      return res.json(parts.map((part) => presenter(part.id, part)));
    } catch (error) {
      logger.error('Failed to read public parts', error, { requestId: req.requestId });
      return res.status(500).json(localizedError(req, 'INTERNAL_ERROR'));
    }
  });

  router.post('/parts', verifyToken, marketplaceWriteLimiter, async (req, res) => {
    try {
      const {
        partName, carBrand, carModel, price, sellerPhone, notes,
        oemNumber, imageBase64, condition, partBrand,
      } = req.body;
      if (!partName || !carBrand || !sellerPhone) {
        return res.status(400).json(localizedError(req, 'PART_FIELDS_REQUIRED'));
      }
      const newPart = {
        ownerId: req.uid,
        partName,
        carBrand,
        carModel: carModel || '',
        price: price || null,
        sellerPhone,
        notes: notes || '',
        oemNumber: oemNumber || null,
        imageBase64: imageBase64 || null,
        condition: condition || null,
        partBrand: partBrand || null,
        createdAt: new Date().toISOString(),
      };
      const docRef = await db.collection('parts').add(newPart);
      return res.json(toOwnerPart(docRef.id, newPart));
    } catch (error) {
      logger.error('Failed to add part', error, { requestId: req.requestId });
      return res.status(500).json(localizedError(req, 'INTERNAL_ERROR'));
    }
  });

  router.delete('/parts/:id', verifyToken, marketplaceWriteLimiter, async (req, res) => {
    try {
      const docRef = db.collection('parts').doc(req.params.id);
      const doc = await docRef.get();
      if (!doc.exists) {
        return res.status(404).json(localizedError(req, 'PART_NOT_FOUND'));
      }
      const part = doc.data();
      if (part.ownerId !== req.uid) {
        return res.status(403).json(localizedError(req, 'PART_DELETE_FORBIDDEN'));
      }
      await docRef.delete();
      return res.json({ success: true });
    } catch (error) {
      logger.error('Failed to delete part', error, { requestId: req.requestId });
      return res.status(500).json(localizedError(req, 'INTERNAL_ERROR'));
    }
  });

  router.put('/parts/:id', verifyToken, marketplaceWriteLimiter, async (req, res) => {
    try {
      const docRef = db.collection('parts').doc(req.params.id);
      const doc = await docRef.get();
      if (!doc.exists) {
        return res.status(404).json(localizedError(req, 'PART_NOT_FOUND'));
      }
      const part = doc.data();
      if (part.ownerId !== req.uid) {
        return res.status(403).json(localizedError(req, 'PART_UPDATE_FORBIDDEN'));
      }
      const {
        partName, carBrand, carModel, price, sellerPhone, notes,
        oemNumber, imageBase64, condition, partBrand,
      } = req.body;
      if (!partName || !carBrand || !sellerPhone) {
        return res.status(400).json(localizedError(req, 'PART_FIELDS_REQUIRED'));
      }
      const updated = {
        ...part,
        ownerId: part.ownerId,
        partName,
        carBrand,
        carModel: carModel || '',
        price: price || null,
        sellerPhone,
        notes: notes || '',
        oemNumber: oemNumber !== undefined ? oemNumber : part.oemNumber || null,
        imageBase64: imageBase64 !== undefined ? imageBase64 : part.imageBase64 || null,
        condition: condition !== undefined ? condition : part.condition || null,
        partBrand: partBrand !== undefined ? partBrand : part.partBrand || null,
      };
      await docRef.set(updated);
      return res.json(toOwnerPart(doc.id, updated));
    } catch (error) {
      logger.error('Failed to update part', error, { requestId: req.requestId });
      return res.status(500).json(localizedError(req, 'INTERNAL_ERROR'));
    }
  });

  return router;
}

module.exports = { createPartsRouter };
