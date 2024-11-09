import { defineConfig } from 'vite';
import laravel from 'laravel-vite-plugin';

export default defineConfig({
    plugins: [
        laravel({
            input: [
                'resources/css/app.css',
                'resources/js/app.js'
            ],
            refresh: true,
            buildDirectory: 'build'
        }),
    ],
    build: {
        manifest: true,
        outDir: 'public/build',
        rollupOptions: {
            input: [
                'resources/css/app.css',
                'resources/js/app.js'
            ]
        },
        assetsDir: '',
        emptyOutDir: true,
    },
    server: {
        hmr: {
            host: 'localhost'
        }
    },
    resolve: {
        alias: {
            '@': '/resources/js'
        }
    }
});