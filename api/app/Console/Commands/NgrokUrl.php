<?php

namespace App\Console\Commands;

use App\Helpers\NgrokHelper;
use Illuminate\Console\Command;

class NgrokUrl extends Command
{
    protected $signature = 'ngrok:url {--copy}';
    protected $description = 'Mostra a URL pública do ngrok';

    public function handle(): int
    {
        $url = NgrokHelper::publicUrl();
        if (!$url) {
            $this->error('ngrok não está rodando. Verifique: docker compose ps ngrok');
            return self::FAILURE;
        }
        $this->info("URL pública: {$url}");
        $this->info("API:        " . NgrokHelper::apiUrl());
        return self::SUCCESS;
    }
}
