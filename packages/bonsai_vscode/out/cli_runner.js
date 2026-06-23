"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.runBonsai = runBonsai;
exports.isBonsaiInstalled = isBonsaiInstalled;
const cp = __importStar(require("child_process"));
async function runBonsai(filePath) {
    return new Promise((resolve) => {
        try {
            const command = cp.spawn('bonsai', ['analyze', '--format', 'json', filePath], {
                stdio: ['ignore', 'pipe', 'pipe'],
            });
            const timeout = setTimeout(() => {
                command.kill();
                resolve(null);
            }, 8000);
            let stdout = '';
            command.stdout.on('data', (chunk) => {
                stdout += chunk.toString();
            });
            command.on('error', () => {
                clearTimeout(timeout);
                resolve(null);
            });
            command.on('close', (code) => {
                clearTimeout(timeout);
                if (code === 2) {
                    resolve(null);
                    return;
                }
                try {
                    const parsed = JSON.parse(stdout);
                    if (!Array.isArray(parsed)) {
                        resolve(null);
                        return;
                    }
                    const result = parsed.find((entry) => entry.file === filePath) ?? null;
                    resolve(result);
                }
                catch (_) {
                    resolve(null);
                }
            });
        }
        catch (_) {
            resolve(null);
        }
    });
}
function isBonsaiInstalled() {
    try {
        const result = cp.spawnSync('bonsai', ['--version'], {
            stdio: 'ignore',
        });
        return result.status === 0;
    }
    catch (_) {
        return false;
    }
}
//# sourceMappingURL=cli_runner.js.map