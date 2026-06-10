const {onRequest} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

const STORAGE_BUCKET = "app-autismo-25f44.firebasestorage.app";

admin.initializeApp({
    storageBucket: STORAGE_BUCKET,
});

exports.proxyStorageCDN = onRequest({
    region: "us-central1",
    invoker: "public",
}, async (req, res) => {
    try {
        const publicPath = stripPublicAssetsPrefix(req.path);
        if (!publicPath) {
            return res.status(400).send("Missing asset path");
        }

        const bucket = admin.storage().bucket();
        const candidates = storagePathCandidates(publicPath);
        const file = await findStorageFile(bucket, candidates);

        if (!file) {
            console.warn("Storage file not found", {
                bucket: STORAGE_BUCKET,
                publicPath,
                candidates,
            });
            return res.status(404).send("File not found");
        }

        res.set("Cache-Control", "public, max-age=31536000, s-maxage=31536000");
        res.set("X-Content-Type-Options", "nosniff");

        const readStream = file.createReadStream();
        readStream.on("error", (error) => {
            console.error("Storage stream error", {
                bucket: STORAGE_BUCKET,
                filePath: file.name,
                code: error.code,
                message: error.message,
            });

            if (!res.headersSent) {
                const statusCode = Number(error.code) || 500;
                res.status(statusCode === 403 ? 403 : 500).send("Storage read error");
            } else {
                res.end();
            }
        });

        readStream.pipe(res);
    } catch (error) {
        console.error("Storage proxy error", {
            bucket: STORAGE_BUCKET,
            path: req.path,
            code: error.code,
            message: error.message,
        });

        const statusCode = Number(error.code) || 500;
        res.status(statusCode === 403 ? 403 : 500).send("Storage proxy error");
    }
});

function stripPublicAssetsPrefix(requestPath) {
    const prefix = "/assets/";
    const path = requestPath || "";

    if (path === "/assets") {
        return "";
    }

    if (path.startsWith(prefix)) {
        return path.slice(prefix.length);
    }

    return path.replace(/^\/+/, "");
}

async function findStorageFile(bucket, candidates) {
    for (const filePath of candidates) {
        const file = bucket.file(filePath);
        try {
            const [exists] = await file.exists();
            if (exists) {
                return file;
            }
        } catch (error) {
            console.error("Storage exists check failed", {
                bucket: STORAGE_BUCKET,
                filePath,
                code: error.code,
                message: error.message,
            });
            throw error;
        }
    }

    return null;
}

function storagePathCandidates(publicPath) {
    const decodedPath = safeDecode(publicPath).replace(/^\/+/, "");
    if (!decodedPath) {
        return [];
    }

    const candidates = [decodedPath];
    if (!decodedPath.startsWith("assets/")) {
        candidates.push(`assets/${decodedPath}`);
    }

    return [...new Set(candidates)];
}

function safeDecode(value) {
    try {
        return decodeURIComponent(value);
    } catch (_) {
        return value;
    }
}
