// ============================================================
// middleware/errorHandler.js
// Centralized error handling middleware
// ============================================================

const errorHandler = (err, req, res, next) => {
    console.error(`[ERROR] ${new Date().toISOString()} - ${err.message}`);
    console.error(err.stack);

    // Multer file size error
    if (err.code === 'LIMIT_FILE_SIZE') {
        return res.status(400).json({
            success: false,
            message: 'Ukuran file terlalu besar. Maksimal 5MB.',
        });
    }

    // Multer unexpected field error
    if (err.code === 'LIMIT_UNEXPECTED_FILE') {
        return res.status(400).json({
            success: false,
            message: 'Field file tidak valid.',
        });
    }

    // Multer file type error
    if (err.message && err.message.includes('Hanya file gambar')) {
        return res.status(400).json({
            success: false,
            message: err.message,
        });
    }

    // Oracle unique constraint violation
    if (err.errorNum === 1) {
        return res.status(409).json({
            success: false,
            message: 'Data sudah ada. Duplikat tidak diizinkan.',
        });
    }

    // Oracle foreign key violation
    if (err.errorNum === 2291 || err.errorNum === 2292) {
        return res.status(400).json({
            success: false,
            message: 'Referensi data tidak valid.',
        });
    }

    // Oracle check constraint violation
    if (err.errorNum === 2290) {
        return res.status(400).json({
            success: false,
            message: 'Nilai tidak memenuhi constraint database.',
        });
    }

    // Default internal server error
    res.status(err.status || 500).json({
        success: false,
        message: process.env.NODE_ENV === 'production'
            ? 'Terjadi kesalahan server. Coba lagi nanti.'
            : err.message,
    });
};

// 404 handler — must be registered before errorHandler
const notFound = (req, res) => {
    res.status(404).json({
        success: false,
        message: `Endpoint tidak ditemukan: ${req.method} ${req.originalUrl}`,
    });
};

module.exports = { errorHandler, notFound };
