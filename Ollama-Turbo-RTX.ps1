# =============================================================================
# Ollama-Turbo-RTX — optimiseur 1-clic pour Ollama sous Windows (GPU NVIDIA RTX)
# -----------------------------------------------------------------------------
# Ce script peut modifier le SYSTEME (avec elevation Admin) :
#   1) Variables d'environnement Machine : OLLAMA_FLASH_ATTENTION, OLLAMA_KV_CACHE_TYPE, OLLAMA_HOST
#   2) Redemarrage des process locaux ollama / llama-server (libere la VRAM)
#   3) Appels API locaux uniquement : http://127.0.0.1:11434 (benchmark)
# Il n'installe aucun .exe tiers, n'envoie aucune telemetrie, ne touche pas au registre hors env Machine.
# =============================================================================
param (
    [string]$Action = "",   # install | install-speed | restore | status | bench (mode CLI)
    [string]$Lang = ""      # en | fr | es | de — sinon auto-detect OS
)

# Affichage UTF-8 pour accents / bandeau ASCII dans la console Windows
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Dictionnaires d'interface (textes menu / messages) — aucune action systeme ici
$i18n = @{
    en = @{
        admin_req      = "[!] Administrator privileges required to configure system environment variables."
        admin_elevate  = "[*] Elevating to Administrator mode..."
        gpu_detect     = "[*] Detecting graphics hardware..."
        gpu_none       = "[ERROR] No compatible NVIDIA GPU detected. Aborting."
        gpu_found      = "[OK] GPU Detected: {0} (~{1} GB VRAM)"
        applying       = "[*] Applying hardware acceleration settings..."
        fa_set         = "  -> OLLAMA_FLASH_ATTENTION = 1 [ENABLED]"
        kv_set         = "  -> OLLAMA_KV_CACHE_TYPE = q8_0 [ENABLED - 50% VRAM saved]"
        kv_clear       = "  -> OLLAMA_KV_CACHE_TYPE = (removed) [FP16 stock - max speed]"
        host_set       = "  -> OLLAMA_HOST = 127.0.0.1:11434 [BIND SECURED]"
        vars_applied   = "[OK] System environment variables applied successfully."
        mode_context   = "[*] Mode: Turbo Context (Flash Attention + KV Q8)"
        mode_speed     = "[*] Mode: Turbo Pure Speed (Flash Attention only)"
        restarting     = "[*] Restarting Ollama daemon..."
        proc_killed    = "  -> Existing Ollama processes stopped."
        restarted_ok   = "[OK] Ollama restarted with new settings!"
        restart_manual = "[!] Please launch Ollama manually from Start Menu."
        revert_title   = "[*] Restoring Ollama factory defaults..."
        revert_ok      = "[OK] Hardware flags removed. Ollama is back to stock settings."
        status_title   = " CURRENT OLLAMA HARDWARE STATUS"
        active_label   = "  ACTIVE MODE     : "
        active_context = "TURBO CONTEXT (FA + Q8)"
        active_speed   = "TURBO PURE SPEED (FA only)"
        active_stock   = "STOCK (no Turbo optimization)"
        active_hint_c  = "  -> Best for long chats / big documents (saves ~50% context VRAM)"
        active_hint_s  = "  -> Best for fastest replies (max quality KV cache, uses more VRAM)"
        active_hint_k  = "  -> Default Ollama settings, no acceleration flags"
        gpu_label      = "  GPU             : "
        gpu_unknown    = "Not detected"
        fa_label       = "  Flash Attention : "
        fa_active      = "ENABLED (1)"
        fa_stock       = "DISABLED (Stock / Conservative)"
        kv_label       = "  KV Cache Type   : "
        kv_opt         = "OPTIMIZED (q8_0 - 50% VRAM context reduction)"
        kv_stock       = "FP16 (Stock - Uncompressed)"
        bind_label     = "  Host Bind       : "
        bind_stock     = "Default (localhost)"
        service_label  = "  Ollama Service  : "
        srv_running    = "RUNNING"
        srv_stopped    = "STOPPED"
        badge_active   = "  << ACTIVE"
        bench_start    = "[*] Running real-time inference speed benchmark..."
        bench_window   = "[OK] Benchmark opened in a separate ADMIN window. Accept the UAC prompt if shown."
        bench_window_fail = "[!] Could not open the benchmark window (UAC cancelled?)."
        bench_admin_ok = "[OK] Running with Administrator privileges."
        bench_wait     = "[*] Waiting for Ollama API to be ready..."
        bench_ready    = "[OK] Ollama API ready."
        bench_not_ready= "[!] Ollama did not become ready in time. Metrics may be invalid."
        bench_warmup   = "[*] Warm-up pass (loading model into VRAM)..."
        bench_api_fail = "[!] API call failed: {0}"
        bench_oom      = "[!] GPU out of memory. Freeing orphan llama-server processes and retrying..."
        bench_not_found= "[!] 'ollama' CLI command not found in system PATH."
        bench_pull     = "[*] Pulling demo model 'llama3.1:8b' (sweet spot 7B/8B + long context)..."
        bench_model    = "[*] Active test model: {0} (~{1})"
        bench_prefer   = "[*] Demo sweet spot: 7B/8B-class model (where stock attention hits O(N^2) limits)."
        bench_prefer14 = "[*] Using a 14B model for the demo (still in the community sweet spot)."
        bench_pick_title = "Choose a model for the benchmark:"
        bench_pick_rec   = "  [0] Recommended (auto) : {0} ({1})  [ctx {2}]"
        bench_pick_item  = "  [{0}] {1} ({2})"
        bench_pick_prompt= "Your choice (0-{0}) [Default: 0 Recommended]"
        bench_pick_using = "  -> Using recommended model: {0}"
        bench_pick_custom= "  -> Custom model selected: {0}"
        bench_ctx      = "[*] Benchmark context set to {0} tokens (long-context stress test)."
        bench_prompt_info = "[*] Stress prompt ready (~{0} chars) to saturate classic attention."
        bench_save_prompt = "Save this comparative report to a text file? (Y/N) [Default: N]"
        bench_running  = "[*] Generating test tokens..."
        bench_res      = "--- Benchmark Results ---"
        bench_time     = "  Total execution time: {0} seconds"
        menu_title     = "Choose an action:"
        menu_help      = "  Tip: pick [1] for long context, [2] for raw speed."
        opt_1          = "  [1] Turbo Context (FA + Q8)"
        opt_1_h1       = "      What it does : Flash Attention + compressed KV cache (q8_0)"
        opt_1_h2       = "      Choose this if: you load long documents / long chats"
        opt_1_h3       = "      Trade-off     : ~50% less VRAM for context, tiny quality cost"
        opt_2          = "  [2] Turbo Pure Speed (FA only)"
        opt_2_h1       = "      What it does : Flash Attention only, KV cache stays FP16"
        opt_2_h2       = "      Choose this if: you want the fastest token generation"
        opt_2_h3       = "      Trade-off     : max speed/quality, uses more VRAM than [1]"
        opt_3          = "  [3] Rollback to Stock Settings"
        opt_3_h1       = "      Removes all Turbo flags and restores Ollama defaults"
        opt_4          = "  [4] Run Real-Time Speed Benchmark (opens in a new window)"
        opt_5          = "  [5] Change Language / Changer de langue"
        opt_6          = "  [6] System Health Check (Ollama / driver / API)"
        opt_7          = "  [7] Smart GPU Preset (auto by VRAM)"
        opt_8          = "  [8] Workflow Preset: Coding (Cursor) or Fast Chat"
        opt_9          = "  [9] Undo / Restore from history snapshot"
        opt_q          = "  [Q] Exit"
        prompt_choice  = "Enter your choice (1-9 or Q)"
        support_tip    = "  Star the repo + Buy me a coffee: buymeacoffee.com/masterm3u"
        health_title   = " SYSTEM HEALTH CHECK"
        smart_title    = " SMART GPU PRESET"
        workflow_title = " WORKFLOW PRESET"
        history_title  = " TURBO HISTORY / UNDO"
        history_empty  = "[!] No snapshots yet. Change a Turbo mode first."
        history_saved  = "[OK] Snapshot saved: {0}"
        history_restored = "[OK] Restored snapshot from {0}"
        export_ok      = "[OK] Exported: {0}"
        reddit_card    = "Reddit / Discord share card copied below — paste freely."
    }
    fr = @{
        admin_req      = "[!] Privileges Administrateur requis pour modifier les variables systeme."
        admin_elevate  = "[*] Elevation des privileges en cours..."
        gpu_detect     = "[*] Detection du materiel graphique..."
        gpu_none       = "[ERREUR] Aucun GPU NVIDIA compatible detecte. Abandon."
        gpu_found      = "[OK] GPU Detecte : {0} (~{1} Go VRAM)"
        applying       = "[*] Application des optimisations materielles..."
        fa_set         = "  -> OLLAMA_FLASH_ATTENTION = 1 [ACTIVE]"
        kv_set         = "  -> OLLAMA_KV_CACHE_TYPE = q8_0 [ACTIVE - 50% VRAM economisee]"
        kv_clear       = "  -> OLLAMA_KV_CACHE_TYPE = (supprime) [FP16 stock - vitesse max]"
        host_set       = "  -> OLLAMA_HOST = 127.0.0.1:11434 [PORT SECURISE]"
        vars_applied   = "[OK] Variables d'environnement appliquees avec succes."
        mode_context   = "[*] Mode : Turbo Contexte (Flash Attention + KV Q8)"
        mode_speed     = "[*] Mode : Turbo Vitesse Pure (Flash Attention seul)"
        restarting     = "[*] Redemarrage du demon Ollama..."
        proc_killed    = "  -> Anciennes instances d'Ollama arretees."
        restarted_ok   = "[OK] Ollama relance avec succes !"
        restart_manual = "[!] Relancez Ollama manuellement depuis le menu Demarrer."
        revert_title   = "[*] Restauration des parametres d'usine d'Ollama..."
        revert_ok      = "[OK] Drapeaux supprimes. Ollama tourne avec ses valeurs par defaut."
        status_title   = " ETAT ACTUEL DE LA CONFIGURATION OLLAMA"
        active_label   = "  MODE ACTIF      : "
        active_context = "TURBO CONTEXTE (FA + Q8)"
        active_speed   = "TURBO VITESSE PURE (FA seul)"
        active_stock   = "STOCK (aucune optimisation Turbo)"
        active_hint_c  = "  -> Ideal pour longs chats / gros documents (~50% VRAM contexte economisee)"
        active_hint_s  = "  -> Ideal pour reponses les plus rapides (cache KV qualite max, plus de VRAM)"
        active_hint_k  = "  -> Reglages d'usine Ollama, aucun drapeau d'acceleration"
        gpu_label      = "  GPU             : "
        gpu_unknown    = "Non detecte"
        fa_label       = "  Flash Attention : "
        fa_active      = "ACTIVE (1)"
        fa_stock       = "DESACTIVE (Par defaut / Conservateur)"
        kv_label       = "  KV Cache Type   : "
        kv_opt         = "OPTIMISE (q8_0 - 50% de VRAM economisee)"
        kv_stock       = "FP16 (Stock - Non compresse)"
        bind_label     = "  Host Bind       : "
        bind_stock     = "Par defaut (localhost)"
        service_label  = "  Service Ollama  : "
        srv_running    = "EN COURS D'EXECUTION"
        srv_stopped    = "ARRETE"
        badge_active   = "  << ACTIF"
        bench_start    = "[*] Execution du test de vitesse (Benchmark)..."
        bench_window   = "[OK] Benchmark ouvert dans une fenetre ADMIN separee. Acceptez le prompt UAC si demande."
        bench_window_fail = "[!] Impossible d'ouvrir la fenetre de benchmark (UAC refuse ?)."
        bench_admin_ok = "[OK] Execution avec privileges Administrateur."
        bench_wait     = "[*] Attente que l'API Ollama soit prete..."
        bench_ready    = "[OK] API Ollama prete."
        bench_not_ready= "[!] Ollama n'est pas pret a temps. Les mesures peuvent etre invalides."
        bench_warmup   = "[*] Passe de chauffe (chargement du modele en VRAM)..."
        bench_api_fail = "[!] Echec appel API : {0}"
        bench_oom      = "[!] Memoire GPU insuffisante. Liberation des process llama-server orphelins puis nouvel essai..."
        bench_not_found= "[!] Commande 'ollama' introuvable dans le PATH systeme."
        bench_pull     = "[*] Telechargement du modele demo 'llama3.1:8b' (sweet spot 7B/8B + long contexte)..."
        bench_model    = "[*] Modele utilise : {0} (~{1})"
        bench_prefer   = "[*] Sweet spot demo : modele classe 7B/8B (la ou l'attention stock plafonne en O(N^2))."
        bench_prefer14 = "[*] Modele 14B utilise pour la demo (toujours dans le sweet spot communaute)."
        bench_pick_title = "Choix du modele pour le benchmark :"
        bench_pick_rec   = "  [0] Recommande automatiquement : {0} ({1})  [ctx {2}]"
        bench_pick_item  = "  [{0}] {1} ({2})"
        bench_pick_prompt= "Votre choix (0-{0}) [Defaut: 0 Recommande]"
        bench_pick_using = "  -> Utilisation du modele recommande : {0}"
        bench_pick_custom= "  -> Modele personnalise selectionne : {0}"
        bench_ctx      = "[*] Contexte du benchmark fixe a {0} tokens (stress long contexte)."
        bench_prompt_info = "[*] Prompt de stress pret (~{0} caracteres) pour saturer l'attention classique."
        bench_save_prompt = "Enregistrer ce rapport comparatif dans un fichier texte ? (O/N) [Defaut: N]"
        bench_running  = "[*] Generation de tokens en cours..."
        bench_res      = "--- Resultats du Benchmark ---"
        bench_time     = "  Temps d'execution total : {0} secondes"
        menu_title     = "Choisissez une action :"
        menu_help      = "  Astuce : [1] = longs contextes, [2] = vitesse brute."
        opt_1          = "  [1] Turbo Contexte (FA + Q8)"
        opt_1_h1       = "      Role        : Flash Attention + cache KV compresse (q8_0)"
        opt_1_h2       = "      A choisir si: vous chargez de longs documents / longs chats"
        opt_1_h3       = "      Compromis   : ~50% de VRAM en moins pour le contexte, legere compression"
        opt_2          = "  [2] Turbo Vitesse Pure (FA seul)"
        opt_2_h1       = "      Role        : Flash Attention seul, cache KV en FP16 (qualite max)"
        opt_2_h2       = "      A choisir si: vous voulez le debit de tokens le plus eleve"
        opt_2_h3       = "      Compromis   : vitesse/qualite max, consomme plus de VRAM que [1]"
        opt_3          = "  [3] Restaurer les reglages d'origine (Rollback)"
        opt_3_h1       = "      Supprime tous les drapeaux Turbo et remet Ollama par defaut"
        opt_4          = "  [4] Lancer un benchmark de vitesse (ouvre une autre fenetre)"
        opt_5          = "  [5] Changer de langue / Switch Language"
        opt_6          = "  [6] Diagnostic systeme (Ollama / driver / API)"
        opt_7          = "  [7] Preset GPU intelligent (auto selon VRAM)"
        opt_8          = "  [8] Preset workflow : Coding (Cursor) ou Chat rapide"
        opt_9          = "  [9] Annuler / Restaurer un snapshot d'historique"
        opt_q          = "  [Q] Quitter"
        prompt_choice  = "Entrez votre choix (1-9 ou Q)"
        support_tip    = "  Etoile GitHub + cafe : buymeacoffee.com/masterm3u"
        health_title   = " DIAGNOSTIC SYSTEME"
        smart_title    = " PRESET GPU INTELLIGENT"
        workflow_title = " PRESET WORKFLOW"
        history_title  = " HISTORIQUE / UNDO"
        history_empty  = "[!] Aucun snapshot. Changez d'abord un mode Turbo."
        history_saved  = "[OK] Snapshot enregistre : {0}"
        history_restored = "[OK] Snapshot restaure : {0}"
        export_ok      = "[OK] Export : {0}"
        reddit_card    = "Carte a coller sur Reddit / Discord ci-dessous."
    }
    es = @{
        admin_req      = "[!] Se requieren permisos de administrador."
        admin_elevate  = "[*] Elevando permisos de administrador..."
        gpu_detect     = "[*] Detectando hardware grafico..."
        gpu_none       = "[ERROR] No se detecto ninguna GPU NVIDIA compatible."
        gpu_found      = "[OK] GPU Detectada: {0} (~{1} GB VRAM)"
        applying       = "[*] Aplicando aceleracion de hardware..."
        fa_set         = "  -> OLLAMA_FLASH_ATTENTION = 1 [ACTIVADO]"
        kv_set         = "  -> OLLAMA_KV_CACHE_TYPE = q8_0 [ACTIVADO - 50% ahorro VRAM]"
        kv_clear       = "  -> OLLAMA_KV_CACHE_TYPE = (eliminado) [FP16 stock - max velocidad]"
        host_set       = "  -> OLLAMA_HOST = 127.0.0.1:11434 [ENLACE SEGURO]"
        vars_applied   = "[OK] Variables de entorno aplicadas con exito."
        mode_context   = "[*] Modo: Turbo Contexto (Flash Attention + KV Q8)"
        mode_speed     = "[*] Modo: Turbo Velocidad Pura (solo Flash Attention)"
        restarting     = "[*] Reiniciando el servicio Ollama..."
        proc_killed    = "  -> Procesos existentes detenidos."
        restarted_ok   = "[OK] Ollama reiniciado con exito!"
        restart_manual = "[!] Inicia Ollama manualmente desde el Menu Inicio."
        revert_title   = "[*] Restaurando configuracion original de Ollama..."
        revert_ok      = "[OK] Parametros eliminados. Ollama vuelve a la configuracion base."
        status_title   = " ESTADO ACTUAL DE HARDWARE OLLAMA"
        active_label   = "  MODO ACTIVO     : "
        active_context = "TURBO CONTEXTO (FA + Q8)"
        active_speed   = "TURBO VELOCIDAD PURA (solo FA)"
        active_stock   = "STOCK (sin optimizacion Turbo)"
        active_hint_c  = "  -> Ideal para chats / documentos largos (~50% menos VRAM de contexto)"
        active_hint_s  = "  -> Ideal para respuestas mas rapidas (KV maxima calidad, mas VRAM)"
        active_hint_k  = "  -> Ajustes de fabrica de Ollama, sin flags de aceleracion"
        gpu_label      = "  GPU             : "
        gpu_unknown    = "No detectada"
        fa_label       = "  Flash Attention : "
        fa_active      = "ACTIVADO (1)"
        fa_stock       = "DESACTIVADO (Predeterminado)"
        kv_label       = "  Tipo de KV Cache: "
        kv_opt         = "OPTIMIZADO (q8_0 - 50% ahorro memoria)"
        kv_stock       = "FP16 (Base - Sin comprimir)"
        bind_label     = "  Host Bind       : "
        bind_stock     = "Predeterminado (localhost)"
        service_label  = "  Servicio Ollama : "
        srv_running    = "EN EJECUCION"
        srv_stopped    = "DETENIDO"
        badge_active   = "  << ACTIVO"
        bench_start    = "[*] Ejecutando benchmark de velocidad en tiempo real..."
        bench_window   = "[OK] Benchmark abierto en una ventana ADMIN aparte. Acepta el UAC si aparece."
        bench_window_fail = "[!] No se pudo abrir la ventana de benchmark (UAC cancelado?)."
        bench_admin_ok = "[OK] Ejecutando con privilegios de Administrador."
        bench_wait     = "[*] Esperando a que la API de Ollama este lista..."
        bench_ready    = "[OK] API de Ollama lista."
        bench_not_ready= "[!] Ollama no estuvo listo a tiempo. Las metricas pueden ser invalidas."
        bench_warmup   = "[*] Pasada de calentamiento (carga del modelo en VRAM)..."
        bench_api_fail = "[!] Fallo de API: {0}"
        bench_oom      = "[!] Sin memoria GPU. Liberando procesos llama-server huerfanos y reintentando..."
        bench_not_found= "[!] Comando 'ollama' no encontrado en el PATH."
        bench_pull     = "[*] Descargando modelo demo 'llama3.1:8b' (sweet spot 7B/8B + contexto largo)..."
        bench_model    = "[*] Modelo activo: {0} (~{1})"
        bench_prefer   = "[*] Sweet spot demo: modelo clase 7B/8B (donde la atencion stock choca con O(N^2))."
        bench_prefer14 = "[*] Usando un modelo 14B para la demo (sigue en el sweet spot de la comunidad)."
        bench_pick_title = "Elige el modelo para el benchmark:"
        bench_pick_rec   = "  [0] Recomendado automaticamente : {0} ({1})  [ctx {2}]"
        bench_pick_item  = "  [{0}] {1} ({2})"
        bench_pick_prompt= "Tu opcion (0-{0}) [Por defecto: 0 Recomendado]"
        bench_pick_using = "  -> Usando el modelo recomendado: {0}"
        bench_pick_custom= "  -> Modelo personalizado seleccionado: {0}"
        bench_ctx      = "[*] Contexto del benchmark fijado a {0} tokens (estres de contexto largo)."
        bench_prompt_info = "[*] Prompt de estres listo (~{0} caracteres) para saturar la atencion clasica."
        bench_save_prompt = "Guardar este informe comparativo en un archivo de texto? (S/N) [Por defecto: N]"
        bench_running  = "[*] Generando tokens de prueba..."
        bench_res      = "--- Resultados del Benchmark ---"
        bench_time     = "  Tiempo total de ejecucion: {0} segundos"
        menu_title     = "Elige una accion:"
        menu_help      = "  Consejo: [1] = contexto largo, [2] = velocidad bruta."
        opt_1          = "  [1] Turbo Contexto (FA + Q8)"
        opt_1_h1       = "      Que hace    : Flash Attention + cache KV comprimida (q8_0)"
        opt_1_h2       = "      Elige esto si: cargas documentos / chats largos"
        opt_1_h3       = "      Compromiso  : ~50% menos VRAM de contexto, leve compresion"
        opt_2          = "  [2] Turbo Velocidad Pura (solo FA)"
        opt_2_h1       = "      Que hace    : solo Flash Attention, KV en FP16 (calidad max)"
        opt_2_h2       = "      Elige esto si: quieres el mayor ritmo de tokens"
        opt_2_h3       = "      Compromiso  : velocidad/calidad max, usa mas VRAM que [1]"
        opt_3          = "  [3] Restaurar configuracion de fabrica"
        opt_3_h1       = "      Elimina todos los flags Turbo y vuelve a los valores por defecto"
        opt_4          = "  [4] Ejecutar benchmark de velocidad (abre otra ventana)"
        opt_5          = "  [5] Cambiar idioma / Change Language"
        opt_q          = "  [Q] Salir"
        prompt_choice  = "Introduce tu opcion (1-9 o Q)"
        support_tip    = "  Estrella GitHub + cafe: buymeacoffee.com/masterm3u"
    }
    de = @{
        admin_req      = "[!] Administratorrechte erforderlich."
        admin_elevate  = "[*] Administratorrechte anfordern..."
        gpu_detect     = "[*] Grafikkarte wird erkannt..."
        gpu_none       = "[FEHLER] Keine kompatible NVIDIA-GPU gefunden."
        gpu_found      = "[OK] GPU erkannt: {0} (~{1} GB VRAM)"
        applying       = "[*] Hardware-Beschleunigung aktivieren..."
        fa_set         = "  -> OLLAMA_FLASH_ATTENTION = 1 [AKTIVIERT]"
        kv_set         = "  -> OLLAMA_KV_CACHE_TYPE = q8_0 [AKTIVIERT - 50% VRAM gespart]"
        kv_clear       = "  -> OLLAMA_KV_CACHE_TYPE = (entfernt) [FP16 Standard - max Tempo]"
        host_set       = "  -> OLLAMA_HOST = 127.0.0.1:11434 [GESICHERT]"
        vars_applied   = "[OK] Umgebungsvariablen erfolgreich angewendet."
        mode_context   = "[*] Modus: Turbo Kontext (Flash Attention + KV Q8)"
        mode_speed     = "[*] Modus: Turbo Reine Geschwindigkeit (nur Flash Attention)"
        restarting     = "[*] Ollama-Dienst wird neu gestartet..."
        proc_killed    = "  -> Bestehende Prozesse beendet."
        restarted_ok   = "[OK] Ollama erfolgreich neu gestartet!"
        restart_manual = "[!] Bitte Ollama manuell starten."
        revert_title   = "[*] Werkseinstellungen wiederherstellen..."
        revert_ok      = "[OK] Optimierungen entfernt. Ollama nutzt Standardwerte."
        status_title   = " AKTUELLER OLLAMA-STATUS"
        active_label   = "  AKTIVER MODUS   : "
        active_context = "TURBO KONTEXT (FA + Q8)"
        active_speed   = "TURBO REINE GESCHWINDIGKEIT (nur FA)"
        active_stock   = "STOCK (keine Turbo-Optimierung)"
        active_hint_c  = "  -> Ideal fuer lange Chats / grosse Dokumente (~50% weniger Kontext-VRAM)"
        active_hint_s  = "  -> Ideal fuer schnellste Antworten (KV max Qualitaet, mehr VRAM)"
        active_hint_k  = "  -> Ollama-Werkseinstellungen, keine Beschleunigungsflags"
        gpu_label      = "  GPU             : "
        gpu_unknown    = "Nicht erkannt"
        fa_label       = "  Flash Attention : "
        fa_active      = "AKTIVIERT (1)"
        fa_stock       = "DEAKTIVIERT (Standard)"
        kv_label       = "  KV Cache Typ    : "
        kv_opt         = "OPTIMIERT (q8_0 - 50% weniger VRAM)"
        kv_stock       = "FP16 (Standard - Unkomprimiert)"
        bind_label     = "  Host Bind       : "
        bind_stock     = "Standard (localhost)"
        service_label  = "  Ollama-Dienst   : "
        srv_running    = "LAEUFT"
        srv_stopped    = "GESTOPPT"
        badge_active   = "  << AKTIV"
        bench_start    = "[*] Geschwindigkeitstest (Benchmark) ausfuehren..."
        bench_window   = "[OK] Benchmark in einem separaten ADMIN-Fenster geoeffnet. UAC ggf. bestaetigen."
        bench_window_fail = "[!] Benchmark-Fenster konnte nicht geoeffnet werden (UAC abgelehnt?)."
        bench_admin_ok = "[OK] Laeuft mit Administratorrechten."
        bench_wait     = "[*] Warte auf bereite Ollama-API..."
        bench_ready    = "[OK] Ollama-API bereit."
        bench_not_ready= "[!] Ollama wurde nicht rechtzeitig bereit. Messwerte koennen ungueltig sein."
        bench_warmup   = "[*] Aufwaerm-Durchlauf (Modell in VRAM laden)..."
        bench_api_fail = "[!] API-Aufruf fehlgeschlagen: {0}"
        bench_oom      = "[!] GPU-Speicher voll. Verwaiste llama-server-Prozesse werden beendet, dann neuer Versuch..."
        bench_not_found= "[!] 'ollama'-Befehl nicht im PATH gefunden."
        bench_pull     = "[*] Lade Demo-Modell 'llama3.1:8b' (Sweet Spot 7B/8B + langer Kontext)..."
        bench_model    = "[*] Test-Modell: {0} (~{1})"
        bench_prefer   = "[*] Demo-Sweet-Spot: 7B/8B-Klasse (wo Stock-Attention an O(N^2) stoesst)."
        bench_prefer14 = "[*] 14B-Modell fuer die Demo (weiterhin Community-Sweet-Spot)."
        bench_pick_title = "Modell fuer den Benchmark waehlen:"
        bench_pick_rec   = "  [0] Empfohlen (auto) : {0} ({1})  [ctx {2}]"
        bench_pick_item  = "  [{0}] {1} ({2})"
        bench_pick_prompt= "Auswahl (0-{0}) [Standard: 0 Empfohlen]"
        bench_pick_using = "  -> Empfohlenes Modell wird genutzt: {0}"
        bench_pick_custom= "  -> Benutzerdefiniertes Modell: {0}"
        bench_ctx      = "[*] Benchmark-Kontext auf {0} Tokens gesetzt (Langkontext-Stresstest)."
        bench_prompt_info = "[*] Stress-Prompt bereit (~{0} Zeichen) zur Sättigung klassischer Attention."
        bench_save_prompt = "Vergleichsbericht als Textdatei speichern? (J/N) [Standard: N]"
        bench_running  = "[*] Token-Generierung laeuft..."
        bench_res      = "--- Benchmark-Ergebnisse ---"
        bench_time     = "  Gesamtdauer: {0} Sekunden"
        menu_title     = "Waehle eine Aktion:"
        menu_help      = "  Tipp: [1] = langer Kontext, [2] = reine Geschwindigkeit."
        opt_1          = "  [1] Turbo Kontext (FA + Q8)"
        opt_1_h1       = "      Funktion    : Flash Attention + komprimierter KV-Cache (q8_0)"
        opt_1_h2       = "      Waehle dies : bei langen Dokumenten / langen Chats"
        opt_1_h3       = "      Kompromiss  : ~50% weniger Kontext-VRAM, leichte Kompression"
        opt_2          = "  [2] Turbo Reine Geschwindigkeit (nur FA)"
        opt_2_h1       = "      Funktion    : nur Flash Attention, KV bleibt FP16 (max Qualitaet)"
        opt_2_h2       = "      Waehle dies : fuer die hoechste Token-Rate"
        opt_2_h3       = "      Kompromiss  : max Tempo/Qualitaet, mehr VRAM als [1]"
        opt_3          = "  [3] Werkseinstellungen wiederherstellen (Rollback)"
        opt_3_h1       = "      Entfernt alle Turbo-Flags und stellt Ollama-Standard wieder her"
        opt_4          = "  [4] Live-Benchmark ausfuehren (neues Fenster)"
        opt_5          = "  [5] Sprache aendern / Change Language"
        opt_q          = "  [Q] Beenden"
        prompt_choice  = "Eingabe (1-9 oder Q)"
        support_tip    = "  GitHub-Stern + Kaffee: buymeacoffee.com/masterm3u"
    }
}

# Choisit la langue UI : parametre -Lang, sinon langue Windows, sinon anglais
function Resolve-Language {
    if ($Lang -and $i18n.ContainsKey($Lang.ToLower())) {
        return $Lang.ToLower()
    }
    try {
        $sysLang = (Get-Culture).TwoLetterISOLanguageName.ToLower()
        if ($i18n.ContainsKey($sysLang)) {
            return $sysLang
        }
    } catch {}
    return "en"
}

$CurrentLang = Resolve-Language
# Fusion : anglais = base (nouvelles cles), langue active ecrase les traductions
$t = @{}; foreach ($k in $i18n.en.Keys) { $t[$k] = $i18n.en[$k] }
if ($CurrentLang -ne "en") { foreach ($k in $i18n[$CurrentLang].Keys) { $t[$k] = $i18n[$CurrentLang][$k] } }

# Chemin disque du .ps1 courant (requis pour relancer en Admin via -File)
function Get-ScriptPath {
    if ($PSCommandPath) { return $PSCommandPath }
    if ($MyInvocation.PSCommandPath) { return $MyInvocation.PSCommandPath }
    if ($PSScriptRoot -and $MyInvocation.MyCommand.Name) {
        return (Join-Path $PSScriptRoot $MyInvocation.MyCommand.Name)
    }
    return $null
}

# True si cette session PowerShell tourne deja avec privileges Administrateur
function Test-IsAdmin {
    return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Si pas Admin : ouvre UNE nouvelle fenetre PowerShell elevee (UAC) puis quitte celle-ci.
# Necessaire car seules les sessions Admin peuvent ecrire les variables d'env. Machine.
function Check-Admin {
    if (Test-IsAdmin) { return }

    Write-Warning $t.admin_req
    Write-Host $t.admin_elevate -ForegroundColor Yellow

    $targetPath = Get-ScriptPath
    if ($targetPath -and (Test-Path $targetPath)) {
        # Conserver Action/Lang pour ne pas perdre le contexte (ex. bench)
        $arg = "-NoProfile -ExecutionPolicy Bypass -NoExit -File `"$targetPath`""
        if ($Action) { $arg += " -Action `"$Action`"" }
        if ($CurrentLang) { $arg += " -Lang `"$CurrentLang`"" }
        Start-Process powershell.exe -ArgumentList $arg -Verb RunAs
    }
    Exit
}

# ECRITURE SYSTEME critique :
# - Persiste OLLAMA_* dans l'environnement Machine (tous les futurs process Ollama)
# - Met a jour aussi $env: de CETTE session (sinon ollama.exe enfant ignorerait le registre)
# FlashAttention / KvCacheType vides = suppression du flag (retour stock)
function Sync-OllamaProcessEnv {
    param(
        [AllowNull()][string]$FlashAttention,
        [AllowNull()][string]$KvCacheType,
        [AllowNull()][string]$HostBind = "127.0.0.1:11434"
    )

    # OLLAMA_FLASH_ATTENTION=1 → active Flash Attention (Tensor Cores) dans le moteur llama.cpp d'Ollama
    if ([string]::IsNullOrEmpty($FlashAttention)) {
        [System.Environment]::SetEnvironmentVariable('OLLAMA_FLASH_ATTENTION', $null, 'Machine')
        Remove-Item Env:\OLLAMA_FLASH_ATTENTION -ErrorAction SilentlyContinue
    } else {
        [System.Environment]::SetEnvironmentVariable('OLLAMA_FLASH_ATTENTION', $FlashAttention, 'Machine')
        $env:OLLAMA_FLASH_ATTENTION = $FlashAttention
    }

    # OLLAMA_KV_CACHE_TYPE=q8_0 → cache KV quantifie (~50% VRAM contexte) ; vide = FP16 stock
    if ([string]::IsNullOrEmpty($KvCacheType)) {
        [System.Environment]::SetEnvironmentVariable('OLLAMA_KV_CACHE_TYPE', $null, 'Machine')
        Remove-Item Env:\OLLAMA_KV_CACHE_TYPE -ErrorAction SilentlyContinue
    } else {
        [System.Environment]::SetEnvironmentVariable('OLLAMA_KV_CACHE_TYPE', $KvCacheType, 'Machine')
        $env:OLLAMA_KV_CACHE_TYPE = $KvCacheType
    }

    # OLLAMA_HOST → adresse d'ecoute locale de l'API (defaut securise 127.0.0.1:11434)
    if ([string]::IsNullOrEmpty($HostBind)) {
        [System.Environment]::SetEnvironmentVariable('OLLAMA_HOST', $null, 'Machine')
        Remove-Item Env:\OLLAMA_HOST -ErrorAction SilentlyContinue
    } else {
        [System.Environment]::SetEnvironmentVariable('OLLAMA_HOST', $HostBind, 'Machine')
        $env:OLLAMA_HOST = $HostBind
    }
}

# Attend que l'API locale Ollama reponde (GET /api/tags) — aucun trafic Internet
function Wait-OllamaReady {
    param([int]$TimeoutSec = 45)
    Write-Host $t.bench_wait -ForegroundColor Cyan
    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    do {
        try {
            $resp = Invoke-RestMethod -Uri "http://127.0.0.1:11434/api/tags" -TimeoutSec 2 -ErrorAction Stop
            if ($null -ne $resp) {
                Write-Host $t.bench_ready -ForegroundColor Green
                return $true
            }
        } catch {}
        Start-Sleep -Milliseconds 500
    } while ((Get-Date) -lt $deadline)

    Write-Warning $t.bench_not_ready
    return $false
}

# Tue les process locaux ollama / "ollama app" / llama-server pour liberer la VRAM GPU.
# Sans ca, un redemarrage partiel laisse d'anciens runners CUDA et provoque des OOM.
function Stop-OllamaSilent {
    $names = @("ollama*", "ollama app*", "llama-server")
    $procs = Get-Process -Name $names -ErrorAction SilentlyContinue
    if ($procs) {
        $procs | Stop-Process -Force -ErrorAction SilentlyContinue
        $deadline = (Get-Date).AddSeconds(8)
        do {
            Start-Sleep -Milliseconds 250
            $still = Get-Process -Name $names -ErrorAction SilentlyContinue
        } while ($still -and (Get-Date) -lt $deadline)
        return $true
    }
    return $false
}

# Decharge les modeles encore en VRAM via l'API locale, puis tue les runners CUDA restants
function Clear-OllamaGpuRunners {
    # Decharge les modeles via API puis tue les runners CUDA restants.
    try {
        $ps = Invoke-RestMethod -Uri "http://127.0.0.1:11434/api/ps" -TimeoutSec 3 -ErrorAction SilentlyContinue
        foreach ($m in @($ps.models)) {
            if (-not $m.name) { continue }
            $unload = @{ model = $m.name; keep_alive = 0; prompt = "" ; stream = $false } | ConvertTo-Json -Compress
            try {
                Invoke-RestMethod -Uri "http://127.0.0.1:11434/api/generate" -Method Post -Body $unload -ContentType "application/json" -TimeoutSec 30 | Out-Null
            } catch {}
        }
    } catch {}
    Get-Process -Name "llama-server" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 800
}

# Relance Ollama en arriere-plan (fenetre masquee) pour prendre en compte les nouveaux flags env
function Start-OllamaSilent {
    $appPath = "$env:LOCALAPPDATA\Programs\Ollama\ollama app.exe"
    $cliPath = "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe"
    if (-not (Test-Path $cliPath)) {
        $cmd = Get-Command "ollama" -ErrorAction SilentlyContinue
        if ($cmd) { $cliPath = $cmd.Source }
    }

    if (Test-Path $appPath) {
        Start-Process -FilePath $appPath -ArgumentList @("hidden", "--fast-startup") -WindowStyle Hidden -ErrorAction SilentlyContinue | Out-Null
        return $true
    }

    if ($cliPath -and (Test-Path $cliPath)) {
        # Fallback serveur headless (aucune UI)
        Start-Process -FilePath $cliPath -ArgumentList "serve" -WindowStyle Hidden -ErrorAction SilentlyContinue | Out-Null
        return $true
    }

    return $false
}

# Cycle complet : stop process Ollama → start silencieux → optionnellement attendre /api/tags
function Restart-Ollama {
    param([switch]$WaitReady)

    Write-Host "`n$($t.restarting)" -ForegroundColor Cyan

    if (Stop-OllamaSilent) {
        Write-Host $t.proc_killed -ForegroundColor Yellow
    }

    if (Start-OllamaSilent) {
        Write-Host $t.restarted_ok -ForegroundColor Green
        if ($WaitReady) {
            Wait-OllamaReady | Out-Null
        } else {
            Start-Sleep -Seconds 2
        }
    } else {
        Write-Host $t.restart_manual -ForegroundColor Yellow
    }
}

# Lit les flags Machine et deduit le mode UI : context | speed | stock
function Get-ActiveTurboMode {
    $fa = [System.Environment]::GetEnvironmentVariable('OLLAMA_FLASH_ATTENTION', 'Machine')
    $kv = [System.Environment]::GetEnvironmentVariable('OLLAMA_KV_CACHE_TYPE', 'Machine')
    if ($fa -eq '1' -and $kv -eq 'q8_0') { return "context" }
    if ($fa -eq '1') { return "speed" }
    return "stock"
}

# Detecte le GPU NVIDIA (nvidia-smi de preference) pour l'affichage statut / rapport — lecture seule
function Get-NvidiaGpuInfo {
    if ($script:CachedGpuInfo) { return $script:CachedGpuInfo }

    $name = $null
    $vramGB = $null

    $smi = Get-Command "nvidia-smi" -ErrorAction SilentlyContinue
    if ($smi) {
        try {
            $raw = & nvidia-smi --query-gpu=name,memory.total --format=csv,noheader,nounits 2>$null
            $line = ($raw | Select-Object -First 1)
            if ($line) {
                $parts = ($line -split ",") | ForEach-Object { $_.Trim() }
                if ($parts.Count -ge 1 -and $parts[0]) { $name = $parts[0] }
                if ($parts.Count -ge 2) {
                    $mb = 0.0
                    if ([double]::TryParse($parts[1], [ref]$mb) -and $mb -gt 0) {
                        $vramGB = [math]::Round($mb / 1024.0, 1)
                    }
                }
            }
        } catch {}
    }

    if (-not $name) {
        $gpu = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -like "*NVIDIA*" -and $_.Name -notlike "*Audio*" } |
            Select-Object -First 1
        if ($gpu) {
            $name = $gpu.Name
            if ($gpu.AdapterRAM -and $gpu.AdapterRAM -gt 0 -and -not $vramGB) {
                $vramGB = [math]::Round($gpu.AdapterRAM / 1GB, 1)
            }
        }
    }

    if ($name -and $vramGB) {
        $script:CachedGpuInfo = "{0} (~{1} GB)" -f $name, $vramGB
    } elseif ($name) {
        $script:CachedGpuInfo = $name
    } else {
        $script:CachedGpuInfo = $null
    }
    return $script:CachedGpuInfo
}

# Snapshot materiel (GPU/CPU/RAM/Windows) pour l'en-tete du rapport de benchmark — lecture seule
function Get-SystemHwInfo {
    if ($script:CachedSystemHw) { return $script:CachedSystemHw }

    $gpu = Get-NvidiaGpuInfo
    if (-not $gpu) { $gpu = "N/A" }

    $cpu = "N/A"
    try {
        $cpuObj = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($cpuObj -and $cpuObj.Name) {
            $cpu = ($cpuObj.Name -replace '\s+', ' ').Trim()
        }
    } catch {}

    $ramGB = "N/A"
    try {
        $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
        if ($cs -and $cs.TotalPhysicalMemory) {
            $ramGB = "{0} GB" -f [math]::Round($cs.TotalPhysicalMemory / 1GB, 0)
        }
    } catch {}

    $windows = "N/A"
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
        if ($os) {
            $caption = ($os.Caption -replace '^Microsoft\s+', '').Trim()
            $arch = $os.OSArchitecture
            if ($os.Version) {
                $windows = "{0} ({1}) — build {2}" -f $caption, $arch, $os.Version
            } else {
                $windows = "{0} ({1})" -f $caption, $arch
            }
        }
    } catch {}

    $script:CachedSystemHw = [pscustomobject]@{
        Gpu     = $gpu
        Cpu     = $cpu
        Ram     = $ramGB
        Windows = $windows
    }
    return $script:CachedSystemHw
}

# Dossier local pour historique / exports (sous %LOCALAPPDATA%, pas dans Program Files)
function Get-TurboDataDir {
    $dir = Join-Path $env:LOCALAPPDATA "Ollama-Turbo-RTX"
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    return $dir
}

function Get-TurboHistoryPath { return (Join-Path (Get-TurboDataDir) "history.json") }

# Capture l'etat Machine AVANT un changement (FA / KV / Host) pour permettre Undo
function Save-TurboHistorySnapshot {
    param([string]$Reason = "change")
    try {
        $path = Get-TurboHistoryPath
        $entries = @()
        if (Test-Path $path) {
            $raw = Get-Content -Path $path -Raw -ErrorAction SilentlyContinue
            if ($raw) { $entries = @($raw | ConvertFrom-Json) }
        }
        $snap = [pscustomobject]@{
            Id        = [guid]::NewGuid().ToString("N").Substring(0, 8)
            Timestamp = (Get-Date).ToString("o")
            Reason    = $Reason
            FA        = [System.Environment]::GetEnvironmentVariable('OLLAMA_FLASH_ATTENTION', 'Machine')
            KV        = [System.Environment]::GetEnvironmentVariable('OLLAMA_KV_CACHE_TYPE', 'Machine')
            Host      = [System.Environment]::GetEnvironmentVariable('OLLAMA_HOST', 'Machine')
        }
        $entries = @($snap) + @($entries)
        if ($entries.Count -gt 30) { $entries = $entries[0..29] }
        ($entries | ConvertTo-Json -Depth 4) | Set-Content -Path $path -Encoding UTF8
        Write-Host ($t.history_saved -f "$($snap.Id) @ $($snap.Timestamp)") -ForegroundColor DarkGray
    } catch {}
}

# MENU [9] — liste les snapshots et restaure FA/KV/Host d'une entree choisie
function Invoke-HistoryRestore {
    Check-Admin
    Write-Host "`n$($t.history_title)" -ForegroundColor Cyan
    $path = Get-TurboHistoryPath
    if (-not (Test-Path $path)) {
        Write-Host $t.history_empty -ForegroundColor Yellow
        return
    }
    $entries = @((Get-Content $path -Raw | ConvertFrom-Json))
    if ($entries.Count -lt 1) {
        Write-Host $t.history_empty -ForegroundColor Yellow
        return
    }
    $max = [math]::Min(10, $entries.Count)
    for ($i = 0; $i -lt $max; $i++) {
        $e = $entries[$i]
        $fa = if ($e.FA) { $e.FA } else { "(none)" }
        $kv = if ($e.KV) { $e.KV } else { "(none)" }
        Write-Host ("  [{0}] {1}  reason={2}  FA={3}  KV={4}" -f ($i + 1), $e.Timestamp, $e.Reason, $fa, $kv) -ForegroundColor White
    }
    Write-Host "  [0] Cancel" -ForegroundColor DarkGray
    $pick = Read-Host "Restore which snapshot"
    if ($pick -notmatch '^[1-9]$' -and $pick -notmatch '^10$') { return }
    $idx = [int]$pick - 1
    if ($idx -lt 0 -or $idx -ge $max) { return }
    $e = $entries[$idx]
    Save-TurboHistorySnapshot -Reason "before-undo-$($e.Id)"
    Sync-OllamaProcessEnv -FlashAttention $e.FA -KvCacheType $e.KV -HostBind $(if ($e.Host) { $e.Host } else { $null })
    Restart-Ollama -WaitReady
    Write-Host ($t.history_restored -f $e.Timestamp) -ForegroundColor Green
    Show-Status
}

# Extrait "0.35.1" depuis "ollama version is 0.35.1" ou "v0.40.11"
function ConvertTo-OllamaVersionObject {
    param([string]$Raw)
    if ([string]::IsNullOrWhiteSpace($Raw)) { return $null }
    if ($Raw -match '(\d+\.\d+\.\d+(?:-[\w\.]+)?)') {
        try { return [version]($Matches[1] -replace '-.*$', '') } catch { return $null }
    }
    return $null
}

# Interroge GitHub Releases (ollama/ollama) pour la derniere version publique + URL OllamaSetup.exe
function Get-LatestOllamaRelease {
    try {
        $headers = @{
            "User-Agent" = "Ollama-Turbo-RTX"
            "Accept"     = "application/vnd.github+json"
        }
        $r = Invoke-RestMethod -Uri "https://api.github.com/repos/ollama/ollama/releases/latest" -Headers $headers -TimeoutSec 8
        $tag = [string]$r.tag_name
        $setup = ($r.assets | Where-Object { $_.name -eq "OllamaSetup.exe" } | Select-Object -First 1)
        return [pscustomobject]@{
            Tag         = $tag
            Version     = (ConvertTo-OllamaVersionObject $tag)
            PublishedAt = $r.published_at
            Url         = $r.html_url
            # CDN officiel pour le DL ; URL GitHub garde pour fallback
            SetupUrl    = "https://ollama.com/download/OllamaSetup.exe"
            GithubSetup = if ($setup) { [string]$setup.browser_download_url } else { $null }
            Ok          = $true
        }
    } catch {
        return [pscustomobject]@{ Ok = $false; Error = $_.Exception.Message }
    }
}

# DL rapide : curl.exe EN PREMIER (choco/winget souvent lents ou bloques sur ~1.5 Go)
function Save-OllamaSetupFast {
    param([string]$Url, [string]$Dest)

    $minBytes = 50MB  # OllamaSetup ~1.5 Go ; refuse les fichiers tronques

    # 1) curl.exe natif Windows = meme vitesse qu'un navigateur (~300 Mo/s chez nous)
    $curl = Get-Command "curl.exe" -ErrorAction SilentlyContinue
    if ($curl) {
        Write-Host "  [*] Telechargement rapide via curl.exe (~1.5 Go, quelques secondes)..." -ForegroundColor Cyan
        # -# = barre compacte ; -L suit le 307 ollama.com -> GitHub
        & curl.exe -L --fail --retry 3 --retry-delay 1 -# -o $Dest $Url
        if ($LASTEXITCODE -eq 0 -and (Test-Path $Dest) -and ((Get-Item $Dest).Length -ge $minBytes)) { return $true }
        Write-Host "  [!!] curl failed (exit $LASTEXITCODE) — trying next method..." -ForegroundColor Yellow
    }

    # 2) BITS
    try {
        Write-Host "  [*] Fast download via BITS ..." -ForegroundColor Cyan
        Start-BitsTransfer -Source $Url -Destination $Dest -ErrorAction Stop
        if ((Test-Path $Dest) -and ((Get-Item $Dest).Length -ge $minBytes)) { return $true }
    } catch {
        Write-Host "  [!!] BITS failed: $($_.Exception.Message)" -ForegroundColor Yellow
    }

    # 3) IWR SANS barre (ProgressPreference = vrai bug de lenteur)
    try {
        Write-Host "  [*] Fallback Invoke-WebRequest (progress OFF) ..." -ForegroundColor DarkGray
        $prev = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue'
        try {
            Invoke-WebRequest -Uri $Url -OutFile $Dest -UseBasicParsing -TimeoutSec 600
        } finally {
            $ProgressPreference = $prev
        }
        if ((Test-Path $Dest) -and ((Get-Item $Dest).Length -ge $minBytes)) { return $true }
    } catch {
        Write-Host "  [!!] IWR failed: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    return $false
}

function Update-OllamaFromRelease {
    param($LatestRelease)

    $cdnUrl = "https://ollama.com/download/OllamaSetup.exe"
    $githubUrl = $null
    if ($LatestRelease) {
        if ($LatestRelease.PSObject.Properties.Name -contains 'GithubSetup' -and $LatestRelease.GithubSetup) {
            $githubUrl = [string]$LatestRelease.GithubSetup
        } elseif ($LatestRelease.SetupUrl -and $LatestRelease.SetupUrl -notlike '*ollama.com/download*') {
            $githubUrl = [string]$LatestRelease.SetupUrl
        }
    }
    # Lien direct GitHub latest (evite un hop inutile si CDN redirect deja)
    if (-not $githubUrl) {
        $githubUrl = "https://github.com/ollama/ollama/releases/latest/download/OllamaSetup.exe"
    }
    $tag = if ($LatestRelease -and $LatestRelease.Tag) { $LatestRelease.Tag } else { "latest" }

    Write-Host "`n  [*] Preparing Ollama update to $tag ..." -ForegroundColor Cyan
    Write-Host "  [*] Stopping local Ollama processes (needed for installer)..." -ForegroundColor DarkGray
    Stop-OllamaSilent | Out-Null

    # --- Methode PRINCIPALE : curl.exe (fiable + rapide ; choco saute car il bloque souvent) ---
    $dest = Join-Path $env:TEMP ("OllamaSetup-{0}-{1}.exe" -f $tag, (Get-Date -Format 'HHmmss'))
    $urls = @($cdnUrl, $githubUrl) | Select-Object -Unique

    $downloaded = $false
    foreach ($setupUrl in $urls) {
        Write-Host "  [*] URL: $setupUrl" -ForegroundColor DarkGray
        Write-Host "      -> $dest" -ForegroundColor DarkGray
        # Nettoyer un eventuel fichier partiel non verrouille
        if (Test-Path $dest) { Remove-Item $dest -Force -ErrorAction SilentlyContinue }
        if (Save-OllamaSetupFast -Url $setupUrl -Dest $dest) {
            $downloaded = $true
            break
        }
        Write-Host "  [!!] Mirror failed, trying next..." -ForegroundColor Yellow
    }

    if (-not $downloaded) {
        # Secours optionnel : Chocolatey avec TIMEOUT (ne plus bloquer indefiniment)
        $choco = Get-Command "choco" -ErrorAction SilentlyContinue
        if ($choco) {
            Write-Host "  [*] Secours Chocolatey (timeout 90s)..." -ForegroundColor Yellow
            $chocoOk = $false
            $job = Start-Job {
                param($c)
                & $c upgrade ollama -y --no-progress 2>&1 | Out-Null
                $LASTEXITCODE
            } -ArgumentList $choco.Source
            if (Wait-Job $job -Timeout 90) {
                $code = Receive-Job $job
                Remove-Job $job -Force -ErrorAction SilentlyContinue
                if ($code -eq 0) { $chocoOk = $true }
                else { Write-Host "  [!!] choco exit $code" -ForegroundColor Yellow }
            } else {
                Write-Host "  [!!] Chocolatey timeout (90s) — abandonne." -ForegroundColor Yellow
                Stop-Job $job -ErrorAction SilentlyContinue
                Remove-Job $job -Force -ErrorAction SilentlyContinue
                Get-Process -Name choco -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
            }
            if ($chocoOk) {
                Start-Sleep -Seconds 2
                $verLine = ""
                try {
                    $ollamaCmd = Get-Command "ollama" -ErrorAction SilentlyContinue
                    if ($ollamaCmd) { $verLine = (& ollama --version 2>$null | Out-String).Trim() }
                } catch {}
                $now = ConvertTo-OllamaVersionObject $verLine
                if ($now -and $LatestRelease.Version -and $now -ge $LatestRelease.Version) {
                    Write-Host ("  [OK] Ollama updated via Chocolatey -> {0}" -f $verLine) -ForegroundColor Green
                    Start-OllamaSilent | Out-Null
                    Wait-OllamaReady | Out-Null
                    return $true
                }
            }
        }

        Write-Host "  [!!] Download failed from all mirrors." -ForegroundColor Red
        Write-Host "       Manual: https://ollama.com/download" -ForegroundColor Yellow
        return $false
    }

    $mb = [math]::Round((Get-Item $dest).Length / 1MB, 1)
    Write-Host "  [OK] Downloaded ${mb} MB — launching installer..." -ForegroundColor Green
    try {
        $p = Start-Process -FilePath $dest -Wait -PassThru -ErrorAction Stop
        Write-Host "  [*] Installer exit code: $($p.ExitCode)" -ForegroundColor DarkGray
    } catch {
        Write-Host "  [!!] Could not start installer: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }

    Start-Sleep -Seconds 2
    $verLine = ""
    try {
        $ollamaCmd = Get-Command "ollama" -ErrorAction SilentlyContinue
        if ($ollamaCmd) {
            $verLine = (& ollama --version 2>$null | Out-String).Trim()
        }
    } catch {}
    $now = ConvertTo-OllamaVersionObject $verLine
    if ($now -and $LatestRelease.Version -and $now -ge $LatestRelease.Version) {
        Write-Host ("  [OK] Ollama updated successfully -> {0}" -f ($(if ($verLine -match '(\d+\.\d+\.\d+)') { $Matches[1] } else { $verLine }))) -ForegroundColor Green
        Write-Host "  [*] Restarting Ollama..." -ForegroundColor DarkGray
        Start-OllamaSilent | Out-Null
        Wait-OllamaReady | Out-Null
        return $true
    }

    Write-Host "  [!!] Version after install: $(if ($verLine) { $verLine } else { 'unknown' })" -ForegroundColor Yellow
    Write-Host "       If the wizard is still open, finish it then re-run Health Check [6]." -ForegroundColor Yellow
    Start-OllamaSilent | Out-Null
    return $false
}

# Interroge l'API NVIDIA (AjaxDriverService) — AUCUN telechargement, liens seuls
function Get-NvidiaGpuProductIds {
    param([string]$GpuName)
    if ([string]::IsNullOrWhiteSpace($GpuName)) { return $null }
    try {
        $headers = @{ "User-Agent" = "Ollama-Turbo-RTX" }
        [xml]$prods = (Invoke-WebRequest -Uri "https://www.nvidia.com/Download/API/lookupValueSearch.aspx?TypeID=3" -Headers $headers -UseBasicParsing -TimeoutSec 12).Content
        $list = @($prods.LookupValueSearch.LookupValues.LookupValue)
        # Match exact / partiel (ex. "NVIDIA GeForce RTX 5080" vs "GeForce RTX 5080")
        $norm = ($GpuName -replace '^NVIDIA\s+', '').Trim()
        $hit = $list | Where-Object { $_.Name -eq "NVIDIA $norm" -or $_.Name -eq $norm -or $_.Name -eq $GpuName } | Select-Object -First 1
        if (-not $hit) {
            $hit = $list | Where-Object { $_.Name -like "*$norm*" -and $_.Name -notlike "*Laptop*" } | Select-Object -First 1
        }
        if (-not $hit -and $norm -match 'Laptop|Notebook') {
            $hit = $list | Where-Object { $_.Name -like "*$norm*" } | Select-Object -First 1
        }
        if (-not $hit) { return $null }
        return [pscustomobject]@{
            Name    = [string]$hit.Name
            Pfid    = [int]$hit.Value
            Psid    = [int]$hit.ParentID
        }
    } catch {
        return $null
    }
}

function Get-LatestNvidiaDriver {
    param(
        [string]$GpuName,
        [string]$InstalledVersion
    )
    $ids = Get-NvidiaGpuProductIds -GpuName $GpuName
    if (-not $ids) {
        return [pscustomobject]@{
            Ok = $false
            Error = "GPU product not found in NVIDIA catalog"
            SearchUrl = "https://www.nvidia.com/Download/index.aspx"
        }
    }

    $osId = 57  # Windows 10 64-bit (drivers couvrent aussi Win11)
    try {
        $cap = (Get-CimInstance Win32_OperatingSystem -ErrorAction Stop).Caption
        if ($cap -match 'Windows 11') { $osId = 135 }
    } catch {}

    $url = "https://gfwsl.geforce.com/services_toolkit/services/com/nvidia/services/AjaxDriverService.php?func=DriverManualLookup&psid=$($ids.Psid)&pfid=$($ids.Pfid)&osID=$osId&languageCode=1033&beta=0&isWHQL=1&dltype=-1&dch=1&upCRD=0&qnf=0&sort1=1&numberOfResults=1"
    try {
        $headers = @{ "User-Agent" = "Ollama-Turbo-RTX"; "Accept" = "application/json" }
        $r = Invoke-RestMethod -Uri $url -Headers $headers -TimeoutSec 15
        if (-not $r -or "$($r.Success)" -ne "1" -or -not $r.IDS) {
            return [pscustomobject]@{ Ok = $false; Error = "NVIDIA API empty"; SearchUrl = "https://www.nvidia.com/Download/index.aspx" }
        }
        $info = $r.IDS[0].downloadInfo
        if (-not $info) { $info = $r.IDS[0] }
        $latest = [string]$info.Version
        $instVer = $null
        $latVer = $null
        try { if ($InstalledVersion -match '(\d+\.\d+)') { $instVer = [version]$Matches[1] } } catch {}
        try { if ($latest -match '(\d+\.\d+)') { $latVer = [version]$Matches[1] } } catch {}
        $update = $false
        if ($instVer -and $latVer -and $latVer -gt $instVer) { $update = $true }

        return [pscustomobject]@{
            Ok              = $true
            ProductName     = $ids.Name
            Installed       = $InstalledVersion
            Latest          = $latest
            UpdateAvailable = $update
            Released        = [uri]::UnescapeDataString([string]$info.ReleaseDateTime)
            Size            = [uri]::UnescapeDataString([string]$info.DownloadURLFileSize)
            DetailsUrl      = [string]$info.DetailsURL
            DownloadUrl     = [string]$info.DownloadURL
            SearchUrl       = "https://www.nvidia.com/Download/index.aspx"
        }
    } catch {
        return [pscustomobject]@{
            Ok = $false
            Error = $_.Exception.Message
            SearchUrl = "https://www.nvidia.com/Download/index.aspx"
        }
    }
}

# MENU [6] — diagnostic + offre de mise a jour Ollama EN FIN de rapport (prompt visible)
function Invoke-HealthCheck {
    Write-Host "`n$($t.health_title)" -ForegroundColor Cyan
    Write-Host ("=" * 60) -ForegroundColor DarkGray

    $pendingUpdate = $null
    $pendingNvidia = $null
    $ollamaCmd = Get-Command "ollama" -ErrorAction SilentlyContinue
    $localVerObj = $null
    if ($ollamaCmd) {
        $ver = ""
        try { $ver = (& ollama --version 2>&1 | Out-String).Trim() } catch {}
        Write-Host "  [OK] ollama CLI : $($ollamaCmd.Source)" -ForegroundColor Green
        $localVerObj = ConvertTo-OllamaVersionObject $ver
        $verShow = if ($localVerObj) { "$localVerObj" } elseif ($ver) { ($ver -split "`n" | Select-Object -Last 1).Trim() } else { "?" }
        Write-Host "       version   : $verShow" -ForegroundColor DarkGray

        Write-Host "  [*] Checking latest Ollama release on GitHub..." -ForegroundColor DarkGray
        $latest = Get-LatestOllamaRelease
        if ($latest.Ok -and $latest.Version -and $localVerObj) {
            if ($localVerObj -ge $latest.Version) {
                Write-Host ("  [OK] Ollama is UP TO DATE  (installed {0} = latest {1})" -f $localVerObj, $latest.Tag) -ForegroundColor Green
            } else {
                Write-Host ("  [!!] Ollama UPDATE AVAILABLE" ) -ForegroundColor Yellow
                Write-Host ("       installed : {0}" -f $localVerObj) -ForegroundColor Yellow
                Write-Host ("       latest    : {0}  (published {1})" -f $latest.Tag, $latest.PublishedAt) -ForegroundColor Yellow
                Write-Host "       download  : https://ollama.com/download" -ForegroundColor Cyan
                Write-Host ("       release   : {0}" -f $latest.Url) -ForegroundColor DarkGray
                $pendingUpdate = $latest
            }
        } elseif ($latest.Ok -and $latest.Tag) {
            Write-Host ("  [--] Latest on GitHub : {0} (could not parse local version)" -f $latest.Tag) -ForegroundColor DarkGray
        } else {
            Write-Host "  [--] Could not reach GitHub releases (offline / rate limit)" -ForegroundColor DarkGray
        }
    } else {
        Write-Host "  [!!] ollama CLI not found in PATH" -ForegroundColor Red
        Write-Host "       Install : https://ollama.com/download" -ForegroundColor Cyan
    }

    $proc = Get-Process -Name "ollama*" -ErrorAction SilentlyContinue
    if ($proc) {
        Write-Host "  [OK] Ollama process running (PID $($proc[0].Id))" -ForegroundColor Green
    } else {
        Write-Host "  [!!] No Ollama process running" -ForegroundColor Yellow
    }

    $smi = Get-Command "nvidia-smi" -ErrorAction SilentlyContinue
    if ($smi) {
        try {
            $line = (& nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader 2>$null | Select-Object -First 1)
            Write-Host "  [OK] NVIDIA driver / GPU : $line" -ForegroundColor Green
            $gpuName = ""
            $drvVer = ""
            if ($line -match '^\s*(.+?),\s*([\d\.]+)\s*,') {
                $gpuName = $Matches[1].Trim()
                $drvVer = $Matches[2].Trim()
            } else {
                try {
                    $gpuName = (& nvidia-smi --query-gpu=name --format=csv,noheader 2>$null | Select-Object -First 1).Trim()
                    $drvVer = (& nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>$null | Select-Object -First 1).Trim()
                } catch {}
            }
            if ($gpuName -and $drvVer) {
                Write-Host "  [*] Checking latest NVIDIA Game Ready driver online..." -ForegroundColor DarkGray
                $nv = Get-LatestNvidiaDriver -GpuName $gpuName -InstalledVersion $drvVer
                if ($nv.Ok) {
                    if ($nv.UpdateAvailable) {
                        Write-Host "  [!!] NVIDIA DRIVER UPDATE AVAILABLE" -ForegroundColor Yellow
                        Write-Host ("       installed : {0}" -f $nv.Installed) -ForegroundColor Yellow
                        Write-Host ("       latest    : {0}  ({1}, {2})" -f $nv.Latest, $nv.Released, $nv.Size) -ForegroundColor Yellow
                        if ($nv.DownloadUrl) {
                            Write-Host ("       download  : {0}" -f $nv.DownloadUrl) -ForegroundColor Cyan
                        }
                        if ($nv.DetailsUrl) {
                            Write-Host ("       details   : {0}" -f $nv.DetailsUrl) -ForegroundColor DarkGray
                        }
                        # Prompt IMMEDIAT (ne pas attendre la fin du rapport — plus visible)
                        Write-Host ""
                        Write-Host "  [Y] Oui — ouvrir le lien web dans le navigateur (aucun DL PowerShell)" -ForegroundColor Green
                        Write-Host "  [N] Non — ignorer et continuer le diagnostic" -ForegroundColor DarkGray
                        try {
                            $nvChoiceNow = [string](Read-Host "  Ouvrir le telechargement NVIDIA maintenant? (Y/N)").Trim()
                        } catch {
                            $nvChoiceNow = "N"
                        }
                        if ($nvChoiceNow -match '^(o|oui|y|yes)$') {
                            $openUrlNow = if ($nv.DownloadUrl) { $nv.DownloadUrl } else { $nv.DetailsUrl }
                            if ($openUrlNow) {
                                Write-Host "  [*] Ouverture du navigateur..." -ForegroundColor Cyan
                                try {
                                    Start-Process $openUrlNow
                                    Write-Host "  [OK] Lien ouvert — telecharge depuis le navigateur." -ForegroundColor Green
                                } catch {
                                    Write-Host "  [!!] Navigateur: $($_.Exception.Message)" -ForegroundColor Red
                                    Write-Host "      $openUrlNow" -ForegroundColor Yellow
                                }
                            }
                        } else {
                            Write-Host "  [--] Driver ignore — diagnostic continue." -ForegroundColor DarkGray
                        }
                        Write-Host ""
                        # Ne pas re-proposer a la fin
                        $pendingNvidia = $null
                    } else {
                        Write-Host ("  [OK] NVIDIA driver UP TO DATE  (installed {0} = latest {1})" -f $nv.Installed, $nv.Latest) -ForegroundColor Green
                    }
                } else {
                    Write-Host ("  [--] NVIDIA driver check skipped: {0}" -f $(if ($nv.Error) { $nv.Error } else { "API unreachable" })) -ForegroundColor DarkGray
                    Write-Host ("       search    : {0}" -f $nv.SearchUrl) -ForegroundColor DarkGray
                }
            }
        } catch {
            Write-Host "  [!!] nvidia-smi failed" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  [!!] nvidia-smi not found (NVIDIA driver tools missing?)" -ForegroundColor Yellow
    }

    try {
        $tags = Invoke-RestMethod -Uri "http://127.0.0.1:11434/api/tags" -TimeoutSec 3 -ErrorAction Stop
        $count = @($tags.models).Count
        Write-Host "  [OK] API http://127.0.0.1:11434 reachable ($count local model(s))" -ForegroundColor Green
    } catch {
        Write-Host "  [!!] API 127.0.0.1:11434 not reachable" -ForegroundColor Red
    }

    try {
        $ps = Invoke-RestMethod -Uri "http://127.0.0.1:11434/api/ps" -TimeoutSec 3 -ErrorAction Stop
        $loaded = @($ps.models)
        if ($loaded.Count -gt 0) {
            foreach ($m in $loaded) {
                Write-Host ("  [OK] Loaded model : {0}" -f $m.name) -ForegroundColor Green
            }
        } else {
            Write-Host "  [--] No model currently loaded in VRAM" -ForegroundColor DarkGray
        }
    } catch {}

    $fa = [System.Environment]::GetEnvironmentVariable('OLLAMA_FLASH_ATTENTION', 'Machine')
    $kv = [System.Environment]::GetEnvironmentVariable('OLLAMA_KV_CACHE_TYPE', 'Machine')
    Write-Host ("  [--] Machine FA={0}  KV={1}" -f $(if ($fa) { $fa } else { "(unset)" }), $(if ($kv) { $kv } else { "(unset)" })) -ForegroundColor DarkGray
    Write-Host ("=" * 60) -ForegroundColor DarkGray

    # --- NVIDIA : Y ouvre le navigateur (aucun DL PowerShell), N continue ---
    if ($pendingNvidia) {
        Write-Host ""
        Write-Host "  ======================================================" -ForegroundColor Yellow
        Write-Host "   DRIVER NVIDIA — MISE A JOUR DISPONIBLE" -ForegroundColor Yellow
        Write-Host ("   Installe / Installed : {0}" -f $pendingNvidia.Installed) -ForegroundColor White
        Write-Host ("   Derniere / Latest    : {0}  ({1})" -f $pendingNvidia.Latest, $pendingNvidia.Size) -ForegroundColor White
        Write-Host "  ======================================================" -ForegroundColor Yellow
        Write-Host "  [Y] Oui / Yes  — ouvrir le lien web (telechargement navigateur)" -ForegroundColor Green
        Write-Host "  [N] Non / No   — ignorer et continuer" -ForegroundColor DarkGray
        Write-Host ""
        try {
            $nvChoice = [string](Read-Host "  Votre choix / Your choice (Y/N)").Trim()
        } catch {
            $nvChoice = "N"
        }
        if ($nvChoice -match '^(o|oui|y|yes)$') {
            $openUrl = if ($pendingNvidia.DownloadUrl) { $pendingNvidia.DownloadUrl } else { $pendingNvidia.DetailsUrl }
            if ($openUrl) {
                Write-Host "  [*] Ouverture du navigateur..." -ForegroundColor Cyan
                Write-Host "      $openUrl" -ForegroundColor DarkGray
                try {
                    Start-Process $openUrl
                    Write-Host "  [OK] Lien ouvert — telecharge et installe depuis le navigateur." -ForegroundColor Green
                } catch {
                    Write-Host "  [!!] Impossible d'ouvrir le navigateur: $($_.Exception.Message)" -ForegroundColor Red
                    Write-Host "      Copie ce lien manuellement: $openUrl" -ForegroundColor Yellow
                }
            } else {
                Write-Host "  [!!] Pas d'URL de telechargement — ouvre: https://www.nvidia.com/Download/index.aspx" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  [--] Mise a jour driver ignoree — on continue." -ForegroundColor DarkGray
        }
    }

    # --- Ollama : Y lance l'installateur (curl), N continue ---
    if ($pendingUpdate) {
        Write-Host ""
        Write-Host "  ======================================================" -ForegroundColor Yellow
        Write-Host "   MISE A JOUR OLLAMA DISPONIBLE / UPDATE AVAILABLE" -ForegroundColor Yellow
        Write-Host ("   Installe / Installed : {0}" -f $localVerObj) -ForegroundColor White
        Write-Host ("   Derniere / Latest    : {0}" -f $pendingUpdate.Tag) -ForegroundColor White
        Write-Host "  ======================================================" -ForegroundColor Yellow
        Write-Host "  [Y] Oui / Yes  — telecharger OllamaSetup.exe et installer" -ForegroundColor Green
        Write-Host "  [N] Non / No   — ignorer pour le moment" -ForegroundColor DarkGray
        Write-Host ""
        try {
            $upd = [string](Read-Host "  Votre choix / Your choice (Y/N)").Trim()
        } catch {
            $upd = "N"
        }
        if ([string]::IsNullOrWhiteSpace($upd) -or $upd -match '^(o|oui|y|yes)$') {
            Write-Host "  [*] Lancement de la mise a jour..." -ForegroundColor Cyan
            [void](Update-OllamaFromRelease -LatestRelease $pendingUpdate)
        } else {
            Write-Host "  [--] Mise a jour ignoree. Relancez [6] quand vous voulez." -ForegroundColor DarkGray
        }
    }
}

# Retourne un preset selon VRAM detectee (evite OOM sur petites cartes)
function Get-GpuSmartPreset {
    $vram = $null
    $smi = Get-Command "nvidia-smi" -ErrorAction SilentlyContinue
    if ($smi) {
        try {
            $mb = (& nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>$null | Select-Object -First 1)
            $n = 0.0
            if ([double]::TryParse(("$mb").Trim(), [ref]$n)) { $vram = [math]::Round($n / 1024.0, 1) }
        } catch {}
    }
    if (-not $vram) {
        return @{ Mode = "context"; CtxHint = 8192; Tier = "unknown"; Why = "GPU VRAM unknown — defaulting to Turbo Context (FA+Q8) as safest speed/VRAM trade-off." }
    }
    if ($vram -lt 10) {
        return @{ Mode = "context"; CtxHint = 4096; Tier = "8GB"; Why = "~${vram} GB VRAM: prefer FA+Q8 and moderate context (~4k) to avoid OOM." }
    }
    if ($vram -lt 14) {
        return @{ Mode = "context"; CtxHint = 8192; Tier = "12GB"; Why = "~${vram} GB VRAM: FA+Q8 recommended; context ~8k is a good default." }
    }
    if ($vram -lt 20) {
        return @{ Mode = "context"; CtxHint = 16384; Tier = "16GB"; Why = "~${vram} GB VRAM: FA+Q8 unlocks long context (~16k) with ~50% KV savings." }
    }
    return @{ Mode = "speed"; CtxHint = 32768; Tier = "24GB+"; Why = "~${vram} GB VRAM: you can run FA-only (FP16 KV) for max quality/speed; use FA+Q8 if you need huge context." }
}

# MENU [7] — propose et applique le preset selon la VRAM
function Invoke-SmartGpuPreset {
    Write-Host "`n$($t.smart_title)" -ForegroundColor Cyan
    $preset = Get-GpuSmartPreset
    Write-Host "  Tier        : $($preset.Tier)" -ForegroundColor White
    Write-Host "  Suggested   : Turbo $($preset.Mode) | ctx hint ~$($preset.CtxHint)" -ForegroundColor Green
    Write-Host "  Why         : $($preset.Why)" -ForegroundColor DarkGray
    Write-Host ""
    $ok = Read-Host "Apply this preset now? (Y/N) [Y]"
    if ($ok -and $ok -notmatch '^(o|oui|y|yes|)$') { return }
    Save-TurboHistorySnapshot -Reason "before-smart-$($preset.Tier)"
    Install-Optimizations -Mode $preset.Mode -SkipHistory
    Write-Host "  Tip: when chatting/coding, keep num_ctx around $($preset.CtxHint) if you hit OOM." -ForegroundColor DarkGray
}

# MENU [8] — Coding/Cursor (FA+Q8 long prompt) vs Fast Chat (FA seul)
function Invoke-WorkflowPreset {
    Write-Host "`n$($t.workflow_title)" -ForegroundColor Cyan
    Write-Host "  [1] Coding / Cursor / VS Code  → Turbo Context (FA + Q8)" -ForegroundColor White
    Write-Host "      Long files & big prompts; saves ~50% context VRAM." -ForegroundColor DarkGray
    Write-Host "  [2] Fast Chat                  → Turbo Pure Speed (FA only)" -ForegroundColor White
    Write-Host "      Snappy short replies; FP16 KV for max quality/speed." -ForegroundColor DarkGray
    Write-Host "  [0] Cancel" -ForegroundColor DarkGray
    $pick = Read-Host "Choice"
    switch ($pick) {
        "1" {
            Save-TurboHistorySnapshot -Reason "before-workflow-coding"
            Write-Host "  Applying Coding / Cursor preset..." -ForegroundColor Magenta
            Install-Optimizations -Mode "context" -SkipHistory
        }
        "2" {
            Save-TurboHistorySnapshot -Reason "before-workflow-chat"
            Write-Host "  Applying Fast Chat preset..." -ForegroundColor Magenta
            Install-Optimizations -Mode "speed" -SkipHistory
        }
        default { return }
    }
}

# Export TXT deja existant + JSON + CSV + carte Reddit (Desktop)
function Export-BenchmarkArtifacts {
    param(
        [string]$Timestamp,
        [string]$TestModel,
        [int]$BenchCtx,
        $Hw,
        $ResStock,
        $ResSpeed,
        $ResContext,
        [double]$GainSpeedE,
        [double]$GainCtxE,
        [string]$BestMode,
        [string]$GainSpeedStr,
        [string]$GainCtxStr,
        [string]$TextReport
    )
    $desktop = [Environment]::GetFolderPath("Desktop")
    $stamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
    $base = Join-Path $desktop "Ollama_Turbo_Bench_$stamp"

    $txtPath = "$base.txt"
    [System.IO.File]::WriteAllText($txtPath, $TextReport, [System.Text.Encoding]::UTF8)
    Write-Host ($t.export_ok -f $txtPath) -ForegroundColor Green

    $obj = [ordered]@{
        tool        = "Ollama-Turbo-RTX"
        timestamp   = $Timestamp
        model       = $TestModel
        context     = $BenchCtx
        method      = "1 warmup + 3 timed passes; reported t/s = average"
        hardware    = @{ gpu = $Hw.Gpu; cpu = $Hw.Cpu; ram = $Hw.Ram; windows = $Hw.Windows }
        results     = @{
            stock_tps           = $ResStock.Eval
            turbo_speed_tps     = $ResSpeed.Eval
            turbo_context_tps   = $ResContext.Eval
            gain_speed_pct      = $GainSpeedE
            gain_context_pct    = $GainCtxE
            winner              = $BestMode
        }
    }
    $jsonPath = "$base.json"
    ($obj | ConvertTo-Json -Depth 6) | Set-Content -Path $jsonPath -Encoding UTF8
    Write-Host ($t.export_ok -f $jsonPath) -ForegroundColor Green

    $csvPath = "$base.csv"
    @(
        "config,tokens_per_sec,gain_vs_stock_pct,kv_vram"
        "stock,$($ResStock.Eval),0,100%"
        "turbo_speed_fa,$($ResSpeed.Eval),$GainSpeedE,100%"
        "turbo_context_fa_q8,$($ResContext.Eval),$GainCtxE,~50%"
    ) | Set-Content -Path $csvPath -Encoding UTF8
    Write-Host ($t.export_ok -f $csvPath) -ForegroundColor Green

    $card = @"
Ollama-Turbo-RTX bench
GPU: $($Hw.Gpu) | $($Hw.Cpu) | RAM $($Hw.Ram)
Model: $TestModel | ctx $BenchCtx | 3-pass avg
Stock: $($ResStock.Eval) t/s
Turbo Speed (FA): $($ResSpeed.Eval) t/s ($GainSpeedStr)
Turbo Context (FA+Q8): $($ResContext.Eval) t/s ($GainCtxStr) | ~-50% KV VRAM
Winner: $BestMode
https://github.com/Masterm3u/Ollama-Turbo-RTX
"@
    $cardPath = "$base-reddit.txt"
    [System.IO.File]::WriteAllText($cardPath, $card, [System.Text.Encoding]::UTF8)
    Write-Host ($t.export_ok -f $cardPath) -ForegroundColor Green
    Write-Host "`n$($t.reddit_card)" -ForegroundColor Yellow
    Write-Host $card -ForegroundColor White
    try { Set-Clipboard -Value $card } catch {}
}

function Show-Status {
    Write-Host "`n========================================================" -ForegroundColor DarkGray
    Write-Host $t.status_title -ForegroundColor Cyan
    Write-Host "========================================================" -ForegroundColor DarkGray

    $fa = [System.Environment]::GetEnvironmentVariable('OLLAMA_FLASH_ATTENTION', 'Machine')
    $kv = [System.Environment]::GetEnvironmentVariable('OLLAMA_KV_CACHE_TYPE', 'Machine')
    $hostBind = [System.Environment]::GetEnvironmentVariable('OLLAMA_HOST', 'Machine')
    $mode = Get-ActiveTurboMode
    $gpuInfo = Get-NvidiaGpuInfo

    Write-Host $t.active_label -NoNewline
    switch ($mode) {
        "context" {
            Write-Host $t.active_context -ForegroundColor Green
            Write-Host $t.active_hint_c -ForegroundColor DarkGray
        }
        "speed" {
            Write-Host $t.active_speed -ForegroundColor Green
            Write-Host $t.active_hint_s -ForegroundColor DarkGray
        }
        default {
            Write-Host $t.active_stock -ForegroundColor Yellow
            Write-Host $t.active_hint_k -ForegroundColor DarkGray
        }
    }
    Write-Host " ------------------------------------------------------" -ForegroundColor DarkGray

    Write-Host $t.gpu_label -NoNewline
    if ($gpuInfo) { Write-Host $gpuInfo -ForegroundColor Green } else { Write-Host $t.gpu_unknown -ForegroundColor Yellow }

    Write-Host $t.fa_label -NoNewline
    if ($fa -eq '1') { Write-Host $t.fa_active -ForegroundColor Green } else { Write-Host $t.fa_stock -ForegroundColor Red }

    Write-Host $t.kv_label -NoNewline
    if ($kv -eq 'q8_0') { Write-Host $t.kv_opt -ForegroundColor Green } else { Write-Host $t.kv_stock -ForegroundColor Yellow }

    Write-Host $t.bind_label -NoNewline
    if ($hostBind) { Write-Host $hostBind -ForegroundColor Green } else { Write-Host $t.bind_stock -ForegroundColor Yellow }

    $running = Get-Process -Name "ollama" -ErrorAction SilentlyContinue
    Write-Host $t.service_label -NoNewline
    if ($running) { Write-Host $t.srv_running -ForegroundColor Green } else { Write-Host $t.srv_stopped -ForegroundColor Red }

    Write-Host "========================================================`n" -ForegroundColor DarkGray
}

function Show-Menu {
    $mode = Get-ActiveTurboMode

    Write-Host $t.menu_title -ForegroundColor Yellow
    Write-Host $t.menu_help -ForegroundColor DarkGray
    Write-Host ""

    Write-Host $t.opt_1 -NoNewline -ForegroundColor White
    if ($mode -eq "context") { Write-Host $t.badge_active -ForegroundColor Green } else { Write-Host "" }
    Write-Host $t.opt_1_h1 -ForegroundColor DarkGray
    Write-Host $t.opt_1_h2 -ForegroundColor DarkGray
    Write-Host $t.opt_1_h3 -ForegroundColor DarkGray
    Write-Host ""

    Write-Host $t.opt_2 -NoNewline -ForegroundColor White
    if ($mode -eq "speed") { Write-Host $t.badge_active -ForegroundColor Green } else { Write-Host "" }
    Write-Host $t.opt_2_h1 -ForegroundColor DarkGray
    Write-Host $t.opt_2_h2 -ForegroundColor DarkGray
    Write-Host $t.opt_2_h3 -ForegroundColor DarkGray
    Write-Host ""

    Write-Host $t.opt_3 -NoNewline -ForegroundColor White
    if ($mode -eq "stock") { Write-Host $t.badge_active -ForegroundColor Yellow } else { Write-Host "" }
    Write-Host $t.opt_3_h1 -ForegroundColor DarkGray
    Write-Host ""

    Write-Host $t.opt_4
    Write-Host $t.opt_5
    Write-Host $t.opt_6
    Write-Host $t.opt_7
    Write-Host $t.opt_8
    Write-Host $t.opt_9
    Write-Host $t.opt_q
    Write-Host ""
    Write-Host $t.support_tip -ForegroundColor DarkYellow
    Write-Host ""
}

# MENU [1]/[2] — applique les flags Turbo sur la machine puis redemarre Ollama
#   context = FA + Q8 KV | speed = FA seul (KV FP16 stock)
function Install-Optimizations {
    param(
        [ValidateSet("context", "speed")]
        [string]$Mode = "context",
        [switch]$SkipHistory
    )

    Check-Admin
    if (-not $SkipHistory) {
        Save-TurboHistorySnapshot -Reason "before-install-$Mode"
    }
    Write-Host "`n$($t.gpu_detect)" -ForegroundColor Cyan
    # Verification lecture seule : refuse d'optimiser sans GPU NVIDIA visible
    $gpu = Get-CimInstance Win32_VideoController | Where-Object { $_.Name -like "*NVIDIA*" -and $_.Name -notlike "*Audio*" } | Select-Object -First 1

    if (-not $gpu) {
        Write-Error $t.gpu_none
        return
    }

    $vramGB = [math]::Round($gpu.AdapterRAM / 1GB, 1)
    if ($vramGB -le 4) {
        # Fallback registre : Win32 AdapterRAM est souvent tronque a 4 Go sur les grosses cartes
        try {
            $regPath = "HKLM:\SYSTEM\ControlSet001\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"
            $qwMemorySize = (Get-ItemProperty -Path $regPath -Name "HardwareInformation.qwMemorySize" -ErrorAction SilentlyContinue)."HardwareInformation.qwMemorySize"
            if ($qwMemorySize) {
                $vramGB = [math]::Round($qwMemorySize / 1GB, 1)
            }
        } catch {}
    }

    Write-Host ($t.gpu_found -f $gpu.Name, $vramGB) -ForegroundColor Green

    if ($Mode -eq "context") {
        Write-Host $t.mode_context -ForegroundColor Magenta
    } else {
        Write-Host $t.mode_speed -ForegroundColor Magenta
    }
    Write-Host $t.applying -ForegroundColor Cyan

    if ($Mode -eq "context") {
        # Turbo Contexte : Flash Attention ON + KV q8_0 (economie VRAM contexte)
        Sync-OllamaProcessEnv -FlashAttention '1' -KvCacheType 'q8_0' -HostBind '127.0.0.1:11434'
        Write-Host $t.fa_set -ForegroundColor Green
        Write-Host $t.kv_set -ForegroundColor Green
    } else {
        # Turbo Vitesse : Flash Attention ON, KV laisse en FP16 (pas de q8_0)
        Sync-OllamaProcessEnv -FlashAttention '1' -KvCacheType $null -HostBind '127.0.0.1:11434'
        Write-Host $t.fa_set -ForegroundColor Green
        Write-Host $t.kv_clear -ForegroundColor Yellow
    }
    Write-Host $t.host_set -ForegroundColor Green

    Write-Host $t.vars_applied -ForegroundColor Green
    Restart-Ollama -WaitReady
    Show-Status
}

# MENU [3] — efface tous les flags Turbo (retour Ollama stock) puis redemarre
function Restore-Defaults {
    Check-Admin
    Save-TurboHistorySnapshot -Reason "before-rollback-stock"
    Write-Host "`n$($t.revert_title)" -ForegroundColor Cyan
    Sync-OllamaProcessEnv -FlashAttention $null -KvCacheType $null -HostBind $null

    Write-Host $t.revert_ok -ForegroundColor Yellow
    Restart-Ollama -WaitReady
    Show-Status
}

# MENU [4] — ouvre une fenetre Admin separee qui execute -Action bench (UAC)
function Start-BenchmarkWindow {
    $scriptPath = Get-ScriptPath
    if (-not $scriptPath -or -not (Test-Path $scriptPath)) {
        Write-Warning $t.bench_window_fail
        return
    }

    $argList = @(
        "-NoProfile"
        "-ExecutionPolicy", "Bypass"
        "-File", $scriptPath
        "-Action", "bench"
        "-Lang", $CurrentLang
    )

    try {
        Start-Process -FilePath "powershell.exe" -ArgumentList $argList -Verb RunAs -ErrorAction Stop | Out-Null
        Write-Host "`n$($t.bench_window)" -ForegroundColor Green
        if (-not (Test-IsAdmin)) {
            Write-Host "  [*] Acceptez le prompt UAC (ecran bleu) pour lancer le bench en Administrateur." -ForegroundColor Yellow
        }
    } catch {
        Write-Warning $t.bench_window_fail
        Write-Host "  [*] UAC refuse ou elevation impossible — le bench doit tourner en admin." -ForegroundColor Red
    }
}

function Get-OllamaApiErrorDetail {
    param($ErrorRecord)
    $detail = $null
    if ($ErrorRecord.ErrorDetails -and $ErrorRecord.ErrorDetails.Message) {
        $detail = $ErrorRecord.ErrorDetails.Message
    }
    if ($detail) {
        try {
            $json = $detail | ConvertFrom-Json -ErrorAction Stop
            if ($json.error) { return [string]$json.error }
        } catch {}
        return [string]$detail
    }
    return $ErrorRecord.Exception.Message
}

# POST local /api/generate — mesure prompt_eval + eval (t/s). keep_alive=0 evite le cache modele.
# Aucun appel Internet : uniquement 127.0.0.1:11434
function Invoke-OllamaGenerateStats {
    param(
        [string]$Model,
        [string]$Prompt,
        [int]$NumPredict = 128,
        [int]$NumCtx = 2048,
        # 0 = decharge immediat apres la requete (mesure reelle, pas de cache resident)
        $KeepAlive = 0
    )

    $payload = @{
        model      = $Model
        prompt     = $Prompt
        stream     = $false
        keep_alive = $KeepAlive
        options    = @{
            num_predict = $NumPredict
            num_ctx     = $NumCtx
        }
    } | ConvertTo-Json -Depth 5

    try {
        $result = Invoke-RestMethod -Uri "http://127.0.0.1:11434/api/generate" -Method Post -Body $payload -ContentType "application/json; charset=utf-8" -TimeoutSec 600
    } catch {
        return @{
            Ok = $false
            Prompt = 0.0
            Eval = 0.0
            Error = (Get-OllamaApiErrorDetail -ErrorRecord $_)
            Oom = ((Get-OllamaApiErrorDetail -ErrorRecord $_) -match 'out of memory|CUDA error|unable to allocate|OOM')
        }
    }

    $pVal = 0.0
    $eVal = 0.0
    if ($result.prompt_eval_duration -gt 0 -and $result.prompt_eval_count -gt 0) {
        $pVal = [math]::Round([double]$result.prompt_eval_count / ([double]$result.prompt_eval_duration / 1e9), 2)
    }
    if ($result.eval_duration -gt 0 -and $result.eval_count -gt 0) {
        $eVal = [math]::Round([double]$result.eval_count / ([double]$result.eval_duration / 1e9), 2)
    }

    return @{ Ok = $true; Prompt = $pVal; Eval = $eVal; Error = $null; Oom = $false }
}

function Format-ModelSize {
    param([long]$Bytes)
    if ($Bytes -le 0) { return "?" }
    if ($Bytes -ge 1GB) { return ("{0:N1} GB" -f ($Bytes / 1GB)) }
    return ("{0:N0} MB" -f ($Bytes / 1MB))
}

function Get-LocalOllamaModels {
    # Modeles locaux exploitables pour le picker (hors cloud).
    $models = @()
    try {
        $tags = Invoke-RestMethod -Uri "http://127.0.0.1:11434/api/tags" -TimeoutSec 5
        if ($tags.models) { $models = @($tags.models) }
    } catch {}

    return @(
        $models | Where-Object {
            $_.size -gt 0 -and
            $_.name -notmatch ':cloud$'
        }
    )
}

function Find-RecommendedBenchmarkModel {
    param([array]$LocalModels)

    $byName = @{}
    foreach ($m in $LocalModels) { $byName[$m.name] = $m }

    # Priorite absolue : qwen-64k s'il est installe (demo long-contexte)
    foreach ($want in @('qwen-64k:latest', 'qwen-64k')) {
        if ($byName.ContainsKey($want)) { return $byName[$want] }
    }
    $match64k = @(
        $LocalModels | Where-Object { $_.name -match '(^|[:\-/])qwen-64k([:\-_]|$)' } |
            Sort-Object { [long]$_.size }
    )
    if ($match64k.Count -gt 0) { return $match64k[0] }

    $priorityExact = @(
        'qwen2.5-coder:7b'
        'llama3.1:8b'
        'llama3:8b'
        'llama3.1:latest'
        'mistral:7b'
        'qwen2.5:7b'
        'deepseek-r1:8b'
        'qwen2.5-coder:14b'
        'qwen2.5:14b'
        'llama3:latest'
        'qwen2.5-coder:latest'
    )

    foreach ($want in $priorityExact) {
        if ($byName.ContainsKey($want)) { return $byName[$want] }
    }

    $match7_8 = @(
        $LocalModels | Where-Object {
            $_.name -match '(^|[:\-_])(7b|8b)([:\-_]|$)' -and
            $_.name -notmatch '70b|72b|65b|32b|34b|31b|26b'
        } | Sort-Object { [long]$_.size }
    )
    if ($match7_8.Count -gt 0) { return $match7_8[0] }

    $match14 = @(
        $LocalModels | Where-Object {
            $_.name -match '(^|[:\-_])14b([:\-_]|$)' -and
            $_.name -notmatch '70b|32b'
        } | Sort-Object { [long]$_.size }
    )
    if ($match14.Count -gt 0) { return $match14[0] }

    $bySize = @(
        $LocalModels | Where-Object {
            [long]$_.size -ge 3.5GB -and [long]$_.size -le 10GB
        } | Sort-Object { [math]::Abs([long]$_.size - 5GB) }
    )
    if ($bySize.Count -gt 0) { return $bySize[0] }

    if ($LocalModels.Count -gt 0) {
        return ($LocalModels | Sort-Object { [long]$_.size } -Descending | Select-Object -First 1)
    }
    return $null
}

function Select-BenchmarkModel {
    # [0] Recommande (7B/8B/14B + ctx 8192) par defaut apres 15s
    # [1..5] Modeles installes (hors cloud) pour un choix pro / quotidien
    $local = Get-LocalOllamaModels

    if ($local.Count -eq 0) {
        Write-Host $t.bench_pull -ForegroundColor Yellow
        ollama pull llama3.1:8b
        return @{ Name = 'llama3.1:8b'; SizeLabel = '~4.9 GB'; Ctx = 8192 }
    }

    $sweetSpot = Find-RecommendedBenchmarkModel -LocalModels $local
    if (-not $sweetSpot) { $sweetSpot = $local[0] }

    # qwen-64k : contexte plus large pour exploiter le sweet spot long-contexte
    $defaultCtx = if ([string]$sweetSpot.name -match '64k') { 16384 } else { 8192 }

    $defaultChoice = @{
        Name      = [string]$sweetSpot.name
        SizeLabel = (Format-ModelSize -Bytes ([long]$sweetSpot.size))
        Ctx       = $defaultCtx
    }

    # Liste personnalisable : les plus recents d'abord (usage Cursor / VS Code)
    $pickerList = @(
        $local | Sort-Object {
            try { [datetime]$_.modified_at } catch { [datetime]::MinValue }
        } -Descending
    )
    $limit = [math]::Min(5, $pickerList.Count)

    Write-Host ""
    Write-Host $t.bench_pick_title -ForegroundColor Yellow
    Write-Host ($t.bench_pick_rec -f $defaultChoice.Name, $defaultChoice.SizeLabel, $defaultChoice.Ctx) -ForegroundColor Green

    for ($i = 0; $i -lt $limit; $i++) {
        $m = $pickerList[$i]
        $label = Format-ModelSize -Bytes ([long]$m.size)
        Write-Host ($t.bench_pick_item -f ($i + 1), $m.name, $label) -ForegroundColor White
    }

    Write-Host ""
    $pick = Read-HostWithTimeout -Prompt ($t.bench_pick_prompt -f $limit) -TimeoutSec 15 -DefaultValue "0"

    if ($pick -match '^[1-5]$') {
        $idx = [int]$pick - 1
        if ($idx -ge 0 -and $idx -lt $limit) {
            $chosen = $pickerList[$idx]
            $name = [string]$chosen.name
            $sizeLabel = Format-ModelSize -Bytes ([long]$chosen.size)
            # Ctx 8192 pour les modeles demonstratifs ; 4096 si tres petit (<2.5 Go) pour eviter OOM inutile
            $ctx = if ([long]$chosen.size -lt 2.5GB) { 4096 } else { 8192 }
            Write-Host ($t.bench_pick_custom -f $name) -ForegroundColor Cyan
            return @{ Name = $name; SizeLabel = $sizeLabel; Ctx = $ctx }
        }
    }

    Write-Host ($t.bench_pick_using -f $defaultChoice.Name) -ForegroundColor DarkGray
    if ($defaultChoice.Name -match '14b') {
        Write-Host $t.bench_prefer14 -ForegroundColor DarkGray
    } else {
        Write-Host $t.bench_prefer -ForegroundColor DarkGray
    }
    return $defaultChoice
}

# Construit un prompt massif (~22k chars) avec GUIDs aleatoires a CHAQUE appel
# → aucun prefixe commun = pas de Prompt Cache Hit qui fausserait les t/s
function New-HeavyStressPrompt {
    # ~22k+ caracteres uniques (~5k tokens) pour forcer un vrai calcul attention O(N^2).
    # Regenere a CHAQUE appel : aucun prefixe reutilisable pour le Prompt Caching Ollama.
    $sb = New-Object System.Text.StringBuilder 24000
    [void]$sb.AppendLine("RunSession-ID: " + [System.Guid]::NewGuid().ToString())
    [void]$sb.AppendLine("Nonce: $(Get-Random -Minimum 100000000 -Maximum 999999999)")
    [void]$sb.AppendLine("You are an expert systems engineer. Analyze the following synthetic telemetry log.")
    [void]$sb.AppendLine("Extract potential latency spikes, memory pressure, and any anomalous checksum patterns.")
    [void]$sb.AppendLine("Then summarize your findings in exactly two sentences.")
    [void]$sb.AppendLine("")

    $targetChars = 22000
    $i = 1
    while ($sb.Length -lt $targetChars) {
        $rndHex = [System.Guid]::NewGuid().ToString("N")
        $rndHex2 = [System.Guid]::NewGuid().ToString("N").Substring(0, 16)
        $alpha = [math]::Round((Get-Random -Minimum 100 -Maximum 9999) / 10.0, 1)
        $beta  = [math]::Round((Get-Random -Minimum 100 -Maximum 9999) / 10.0, 1)
        $gamma = Get-Random -Minimum 1000 -Maximum 99999
        $ts = Get-Date -Format "yyyyMMdd-HHmmss.fff"
        [void]$sb.AppendLine("TRACE-LOG-ENTRY-[$i] TIMESTAMP=$ts ADDR=0x$rndHex METRIC_ALPHA=$alpha METRIC_BETA=$beta METRIC_GAMMA=$gamma")
        [void]$sb.AppendLine("  -> Payload block $i : verification vector checksum=$rndHex2 status=INSPECTED flags=0x00FF44 lane=$(($i % 32) + 1) queue=$([math]::Round($alpha * $beta, 2))")
        [void]$sb.AppendLine("  -> CUDA_NOTE seed=$rndHex2 warp_group=$(($i % 8)) occupancy_hint=$((40 + ($i % 55)))% kv_pressure=$([math]::Round(($i / 10.0), 1))MB")
        $i++
        if ($i -gt 500) { break }
    }

    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("END OF TRACE. Provide the two-sentence summary now.")
    return $sb.ToString()
}

# Alias de compatibilite
function New-BenchmarkStressPrompt { return (New-HeavyStressPrompt) }

# API Win32 user32/kernel32 : redimensionner la VRAIE fenetre Terminal (pas le buffer console)
# — lecture/positionnement UI uniquement, aucune donnee reseau
if (-not ("OllamaTurboWin" -as [type])) {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class OllamaTurboWin {
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
    [StructLayout(LayoutKind.Sequential)] public struct MONITORINFO {
        public int cbSize; public RECT rcMonitor; public RECT rcWork; public uint dwFlags;
    }
    [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
    [DllImport("user32.dll")] public static extern bool IsZoomed(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT r);
    [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr hWnd, int x, int y, int w, int h, bool repaint);
    [DllImport("user32.dll")] public static extern IntPtr MonitorFromWindow(IntPtr hWnd, uint flags);
    [DllImport("user32.dll")] public static extern bool GetMonitorInfo(IntPtr hMon, ref MONITORINFO mi);
    [DllImport("user32.dll")] public static extern IntPtr SetThreadDpiAwarenessContext(IntPtr ctx);
}
"@
}

# Retrouve le handle HWND de la fenetre visible (conhost classique ou Windows Terminal)
function Get-TerminalWindowHandle {
    if (-not $env:WT_SESSION) {
        return [OllamaTurboWin]::GetConsoleWindow()
    }
    $hwnd = [OllamaTurboWin]::GetForegroundWindow()
    if ($hwnd -eq [IntPtr]::Zero) { return [IntPtr]::Zero }
    $procId = [uint32]0
    [void][OllamaTurboWin]::GetWindowThreadProcessId($hwnd, [ref]$procId)
    $proc = Get-Process -Id $procId -ErrorAction SilentlyContinue
    if ($proc -and $proc.ProcessName -like "WindowsTerminal*") { return $hwnd }
    return [IntPtr]::Zero
}

# Agrandit la fenetre a la hauteur utile de l'ecran (une seule fois) pour voir le titre ASCII
function Resize-TerminalFullHeight {
    if ($script:TerminalResized) { return }
    $script:TerminalResized = $true
    try {
        try { [void][OllamaTurboWin]::SetThreadDpiAwarenessContext([IntPtr](-4)) } catch {}
        $hwnd = Get-TerminalWindowHandle
        if ($hwnd -eq [IntPtr]::Zero -or [OllamaTurboWin]::IsZoomed($hwnd)) { return }

        $rect = New-Object OllamaTurboWin+RECT
        [void][OllamaTurboWin]::GetWindowRect($hwnd, [ref]$rect)
        $mi = New-Object OllamaTurboWin+MONITORINFO
        $mi.cbSize = [System.Runtime.InteropServices.Marshal]::SizeOf($mi)
        $mon = [OllamaTurboWin]::MonitorFromWindow($hwnd, 2)
        if (-not [OllamaTurboWin]::GetMonitorInfo($mon, [ref]$mi)) { return }

        $work = $mi.rcWork
        $width = [math]::Min($rect.Right - $rect.Left, $work.Right - $work.Left)
        $left = [math]::Max($work.Left, [math]::Min($rect.Left, $work.Right - $width))
        $rowsBefore = [Console]::WindowHeight
        [void][OllamaTurboWin]::MoveWindow($hwnd, $left, $work.Top, $width, $work.Bottom - $work.Top, $true)

        for ($i = 0; $i -lt 20 -and [Console]::WindowHeight -eq $rowsBefore; $i++) {
            Start-Sleep -Milliseconds 50
        }
    } catch {}
}

function Initialize-MenuConsole {
    try { $host.UI.RawUI.WindowTitle = "Ollama Turbo RTX" } catch {}
    Resize-TerminalFullHeight
    Clear-Host
}

function Initialize-BenchConsole {
    try { $host.UI.RawUI.WindowTitle = "Ollama Turbo Benchmark [ADMIN]" } catch {}
    Resize-TerminalFullHeight
    Clear-Host
}

# MENU [4] / -Action bench — compare Stock vs FA vs FA+Q8 (moyenne de 3 passes chacune)
# Modifie temporairement les flags Machine pendant le test, puis RESTAURE l'etat initial.
function Run-Benchmark {
    Check-Admin
    Initialize-BenchConsole
    Write-Host $t.bench_admin_ok -ForegroundColor Green
    Write-Host "`n$($t.bench_start)" -ForegroundColor Cyan

    $ollamaBin = Get-Command "ollama" -ErrorAction SilentlyContinue
    if (-not $ollamaBin) {
        Write-Warning $t.bench_not_found
        return
    }

    # Sauvegarde stricte : on remettra exactement ces valeurs a la fin du bench
    $origFA = [System.Environment]::GetEnvironmentVariable('OLLAMA_FLASH_ATTENTION', 'Machine')
    $origKV = [System.Environment]::GetEnvironmentVariable('OLLAMA_KV_CACHE_TYPE', 'Machine')
    $origHost = [System.Environment]::GetEnvironmentVariable('OLLAMA_HOST', 'Machine')
    if ([string]::IsNullOrEmpty($origHost)) { $origHost = '127.0.0.1:11434' }

    $env:OLLAMA_HOST = "127.0.0.1:11434"
    if (-not (Wait-OllamaReady)) {
        Restart-Ollama -WaitReady
    }

    Clear-OllamaGpuRunners
    if (-not (Wait-OllamaReady)) {
        Restart-Ollama -WaitReady
    }

    $modelInfo = Select-BenchmarkModel
    $testModel = $modelInfo.Name
    $benchCtx = if ($modelInfo.Ctx -and $modelInfo.Ctx -gt 0) { [int]$modelInfo.Ctx } else { 8192 }
    # Echantillon pour afficher la taille ; chaque passe regenere un prompt UNIQUE (anti-cache)
    $samplePrompt = New-HeavyStressPrompt
    Write-Host ($t.bench_model -f $testModel, $modelInfo.SizeLabel) -ForegroundColor Green
    Write-Host ($t.bench_ctx -f $benchCtx) -ForegroundColor DarkGray
    Write-Host ($t.bench_prompt_info -f $samplePrompt.Length) -ForegroundColor DarkGray
    Write-Host "  [*] Prompt regenere a chaque passe (~5k tokens uniques) + keep_alive=0" -ForegroundColor DarkGray

    # Pour UN mode donne : 1 warm-up (ignore) + 3 generations chronometrees → moyenne t/s
    function Execute-3Passes {
        param([string]$PhaseName)
        Write-Host "`n[*] $PhaseName (3 passes en cours)..." -ForegroundColor Yellow
        Write-Host "  [*] Cache bust: New-HeavyStressPrompt() + keep_alive=0 (attention O(N^2) reelle)" -ForegroundColor DarkGray

        Write-Host "  $($t.bench_warmup)" -ForegroundColor DarkGray
        $warmPrompt = New-HeavyStressPrompt
        $warm = Invoke-OllamaGenerateStats -Model $testModel -Prompt $warmPrompt -NumPredict 16 -NumCtx $benchCtx -KeepAlive 0
        if (-not $warm.Ok) {
            if ($warm.Oom) {
                Write-Host "  $($t.bench_oom)" -ForegroundColor Yellow
                Clear-OllamaGpuRunners
                Restart-Ollama -WaitReady
                $warmPrompt = New-HeavyStressPrompt
                $warm = Invoke-OllamaGenerateStats -Model $testModel -Prompt $warmPrompt -NumPredict 16 -NumCtx $benchCtx -KeepAlive 0
            }
            if (-not $warm.Ok) {
                Write-Host ("  " + ($t.bench_api_fail -f $warm.Error)) -ForegroundColor Red
            }
        }
        Clear-OllamaGpuRunners

        $pRates = @()
        $eRates = @()

        for ($i = 1; $i -le 3; $i++) {
            Write-Host "  -> Passe $i/3..." -NoNewline -ForegroundColor Gray

            # Texte massif entierement regeneré : aucun prefixe commun = pas de Prompt Cache Hit
            $realPrompt = New-HeavyStressPrompt

            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $stats = Invoke-OllamaGenerateStats -Model $testModel -Prompt $realPrompt -NumPredict 128 -NumCtx $benchCtx -KeepAlive 0
            $sw.Stop()

            if (-not $stats.Ok -and $stats.Oom) {
                Write-Host " OOM - retry..." -ForegroundColor Yellow
                Clear-OllamaGpuRunners
                Restart-Ollama -WaitReady
                $realPrompt = New-HeavyStressPrompt
                $sw.Restart()
                $stats = Invoke-OllamaGenerateStats -Model $testModel -Prompt $realPrompt -NumPredict 128 -NumCtx $benchCtx -KeepAlive 0
                $sw.Stop()
            }

            if (-not $stats.Ok) {
                Write-Host (" FAIL | " + ($t.bench_api_fail -f $stats.Error)) -ForegroundColor Red
                continue
            }

            if ($stats.Prompt -gt 0) { $pRates += $stats.Prompt }
            if ($stats.Eval -gt 0) { $eRates += $stats.Eval }

            Write-Host " OK ($([math]::Round($sw.Elapsed.TotalSeconds, 2))s) | Prompt: $($stats.Prompt) t/s | Gen: $($stats.Eval) t/s | chars=$($realPrompt.Length)" -ForegroundColor DarkGray
        }

        # Purge totale avant le mode suivant (Stock / Vitesse / Contexte)
        Clear-OllamaGpuRunners

        $avgP = if ($pRates.Count -gt 0) { [math]::Round(($pRates | Measure-Object -Average).Average, 2) } else { 0 }
        $avgE = if ($eRates.Count -gt 0) { [math]::Round(($eRates | Measure-Object -Average).Average, 2) } else { 0 }
        return @{ Prompt = $avgP; Eval = $avgE }
    }

    function Get-GainPct {
        param([double]$Base, [double]$Value)
        if ($Base -le 0) { return 0 }
        return [math]::Round((($Value - $Base) / $Base) * 100, 1)
    }

    function Format-Gain {
        param([double]$Pct)
        $sign = if ($Pct -gt 0) { "+" } else { "" }
        return "$sign$Pct %"
    }

    function Get-GainColor {
        param([double]$Pct)
        if ($Pct -gt 0) { return "Green" }
        if ($Pct -lt 0) { return "Red" }
        return "Yellow"
    }

    # ----- Phase 1/3 : reference Windows stock (pas de FA, pas de Q8) -----
    Write-Host "`n>>> ETAPE 1/3 : STOCK (aucune optimisation)..." -ForegroundColor Cyan
    Sync-OllamaProcessEnv -FlashAttention $null -KvCacheType $null -HostBind '127.0.0.1:11434'
    Clear-OllamaGpuRunners
    Restart-Ollama -WaitReady
    $resStock = Execute-3Passes -PhaseName "Mesure Mode STOCK"

    # ----- Phase 2/3 : Flash Attention seul (KV FP16) -----
    Write-Host "`n>>> ETAPE 2/3 : TURBO VITESSE PURE (Flash Attention seul)..." -ForegroundColor Cyan
    Sync-OllamaProcessEnv -FlashAttention '1' -KvCacheType $null -HostBind '127.0.0.1:11434'
    Clear-OllamaGpuRunners
    Restart-Ollama -WaitReady
    $resSpeed = Execute-3Passes -PhaseName "Mesure Mode TURBO VITESSE PURE"

    # ----- Phase 3/3 : Flash Attention + KV q8_0 -----
    Write-Host "`n>>> ETAPE 3/3 : TURBO CONTEXTE (Flash Attention + Q8)..." -ForegroundColor Cyan
    Sync-OllamaProcessEnv -FlashAttention '1' -KvCacheType 'q8_0' -HostBind '127.0.0.1:11434'
    Clear-OllamaGpuRunners
    Restart-Ollama -WaitReady
    $resContext = Execute-3Passes -PhaseName "Mesure Mode TURBO CONTEXTE"

    # ----- Fin de mesure : remet EXACTEMENT les flags Machine d'avant le bench -----
    Write-Host "`n[*] Restauration de l'etat initial de votre machine..." -ForegroundColor Cyan
    Sync-OllamaProcessEnv -FlashAttention $origFA -KvCacheType $origKV -HostBind $origHost
    Restart-Ollama -WaitReady

    # Calcul des gains % vs Stock (moyennes des 3 passes)
    $gainSpeedE = Get-GainPct -Base $resStock.Eval -Value $resSpeed.Eval
    $gainCtxE   = Get-GainPct -Base $resStock.Eval -Value $resContext.Eval

    $bestMode = "Stock"
    $maxSpeed = $resStock.Eval
    if ($resSpeed.Eval -gt $maxSpeed) {
        $bestMode = "Turbo Vitesse (FA)"
        $maxSpeed = $resSpeed.Eval
    }
    if ($resContext.Eval -gt $maxSpeed) {
        $bestMode = "Turbo Contexte (FA + Q8)"
        $maxSpeed = $resContext.Eval
    }

    $gainSpeedStr = if ($gainSpeedE -gt 0) { "+$gainSpeedE %" } else { "$gainSpeedE %" }
    $gainCtxStr   = if ($gainCtxE -gt 0)   { "+$gainCtxE %" }   else { "$gainCtxE %" }
    $badgeCtx     = if ($gainCtxE -gt 10)  { " [GAIN NET]" } else { "" }
    $badgeSpeed   = if ($gainSpeedE -gt 10){ " [GAIN NET]" } else { "" }

    $hw = Get-SystemHwInfo
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $sepLine = "=" * 82
    $subLine = "-" * 82

    Write-Host ""
    Write-Host $sepLine -ForegroundColor DarkGray
    Write-Host " RAPPORT DE PERFORMANCE OLLAMA : STOCK vs TURBO" -ForegroundColor Cyan
    Write-Host " Date     : $timestamp" -ForegroundColor DarkGray
    Write-Host " Modele   : $testModel" -ForegroundColor DarkGray
    Write-Host " Contexte : $benchCtx tokens" -ForegroundColor DarkGray
    Write-Host " Methode  : 1 warm-up + 3 passes par mode ; t/s = moyenne des 3" -ForegroundColor DarkGray
    Write-Host " GPU      : $($hw.Gpu)" -ForegroundColor Green
    Write-Host " CPU      : $($hw.Cpu)" -ForegroundColor Green
    Write-Host " RAM      : $($hw.Ram)" -ForegroundColor Green
    Write-Host " Windows  : $($hw.Windows)" -ForegroundColor Green
    Write-Host $sepLine -ForegroundColor DarkGray
    Write-Host (" {0,-26} | {1,18} | {2,14} | {3,13} " -f "CONFIGURATION", "GENERATION (t/s)", "GAIN VITESSE", "GAIN VRAM") -ForegroundColor Yellow
    Write-Host $subLine -ForegroundColor DarkGray
    Write-Host "  (valeurs = moyenne de 3 essais apres warm-up)" -ForegroundColor DarkGray

    Write-Host (" {0,-26} | {1,14} t/s | {2,14} | {3,13} " -f "[Stock] Par defaut", [string]$resStock.Eval, "(Reference)", "Aucun (100%)") -ForegroundColor Gray

    $colorSpeed = if ($gainSpeedE -ge 0) { [ConsoleColor]::Green } else { [ConsoleColor]::Red }
    Write-Host (" {0,-26} | {1,14} t/s | {2,14} | {3,13} " -f "[2] Turbo Vitesse (FA)", [string]$resSpeed.Eval, "$gainSpeedStr$badgeSpeed", "Aucun (100%)") -ForegroundColor $colorSpeed

    $colorCtx = if ($gainCtxE -ge 0) { [ConsoleColor]::Green } else { [ConsoleColor]::Red }
    Write-Host (" {0,-26} | {1,14} t/s | {2,14} | {3,13} " -f "[1] Turbo Contexte (FA+Q8)", [string]$resContext.Eval, "$gainCtxStr$badgeCtx", "-50 % VRAM") -ForegroundColor $colorCtx

    Write-Host $sepLine -ForegroundColor DarkGray
    Write-Host " RECOMMANDATION SYSTEME :" -ForegroundColor Yellow
    if ($bestMode -eq "Turbo Contexte (FA + Q8)") {
        Write-Host " -> Activez l'option [1] Turbo Contexte (FA + Q8)" -ForegroundColor Green
        Write-Host " -> Benefice direct : +$gainCtxE % de debit et la moitie de la memoire VRAM economisee !" -ForegroundColor White
    } elseif ($bestMode -eq "Turbo Vitesse (FA)") {
        Write-Host " -> Activez l'option [2] Turbo Vitesse Pure (FA seul)" -ForegroundColor Green
        Write-Host " -> Benefice direct : Debit maximal sans compression de cache." -ForegroundColor White
    } else {
        Write-Host " -> Le mode [Stock] par defaut offre deja les meilleures performances sur ce modele." -ForegroundColor Yellow
    }
    Write-Host $sepLine -ForegroundColor DarkGray
    Write-Host ""

    $report = @"
================================================================================
 RAPPORT DE PERFORMANCE OLLAMA : STOCK vs TURBO
 Date     : $timestamp
 Modele   : $testModel
 Contexte : $benchCtx tokens
 Methode  : 1 warm-up + 3 passes par mode ; t/s = moyenne des 3 essais
 GPU      : $($hw.Gpu)
 CPU      : $($hw.Cpu)
 RAM      : $($hw.Ram)
 Windows  : $($hw.Windows)
================================================================================
 CONFIGURATION              GENERATION (Tokens/s)   GAIN VITESSE    GAIN VRAM
--------------------------------------------------------------------------------
 [Stock] Par defaut                 $($resStock.Eval) t/s       (Reference)      Aucun (100%)
 [2] Turbo Vitesse (FA)             $($resSpeed.Eval) t/s        $gainSpeedStr          Aucun (100%)
 [1] Turbo Contexte (FA + Q8)       $($resContext.Eval) t/s        $gainCtxStr          -50 % VRAM
================================================================================
 Note : chaque t/s ci-dessus est la MOYENNE de 3 generations (apres 1 warm-up).
        Prompt unique a chaque passe (anti-cache) + keep_alive=0.
================================================================================
 RECOMMANDATION :
 -> Meilleure configuration detectee : $bestMode
================================================================================
"@

    $saveChoice = Read-HostWithTimeout -Prompt $t.bench_save_prompt -TimeoutSec 20 -DefaultValue "Y"
    if ($saveChoice -match '^(o|oui|y|yes|s|si|j|ja)?$') {
        Export-BenchmarkArtifacts `
            -Timestamp $timestamp -TestModel $testModel -BenchCtx $benchCtx -Hw $hw `
            -ResStock $resStock -ResSpeed $resSpeed -ResContext $resContext `
            -GainSpeedE $gainSpeedE -GainCtxE $gainCtxE -BestMode $bestMode `
            -GainSpeedStr $gainSpeedStr -GainCtxStr $gainCtxStr -TextReport $report
        $latestTxt = Get-ChildItem ([Environment]::GetFolderPath("Desktop")) -Filter "Ollama_Turbo_Bench_*.txt" |
            Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($latestTxt) { Start-Process notepad.exe -ArgumentList "`"$($latestTxt.FullName)`"" }
        Start-Sleep -Seconds 1
    }
}

function Stop-BenchmarkHost {
    # Fermeture immediate apres la reponse O/N (pas de countdown)
    try {
        Stop-Process -Id $PID -Force -ErrorAction SilentlyContinue
    } catch {}
    Exit 0
}

function Read-HostWithTimeout {
    param(
        [string]$Prompt,
        [int]$TimeoutSec = 20,
        [string]$DefaultValue = "N"
    )

    Write-Host "$Prompt : " -NoNewline
    $buffer = ""
    $deadline = (Get-Date).AddSeconds($TimeoutSec)

    while ((Get-Date) -lt $deadline) {
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            if ($key.Key -eq "Enter") {
                Write-Host ""
                if ([string]::IsNullOrWhiteSpace($buffer)) { return $DefaultValue }
                return $buffer.Trim()
            }
            if ($key.Key -eq "Escape") {
                Write-Host ""
                return $DefaultValue
            }
            if ($key.Key -eq "Backspace") {
                if ($buffer.Length -gt 0) {
                    $buffer = $buffer.Substring(0, $buffer.Length - 1)
                    Write-Host "`b `b" -NoNewline
                }
                continue
            }
            if ($key.KeyChar -and [int][char]$key.KeyChar -ge 32) {
                $buffer += $key.KeyChar
                Write-Host $key.KeyChar -NoNewline
            }
        }
        Start-Sleep -Milliseconds 100
    }

    Write-Host ""
    Write-Host "  -> ($DefaultValue)" -ForegroundColor DarkGray
    return $DefaultValue
}

function Select-Language {
    Write-Host "`nSelect Language / Choisir la langue :" -ForegroundColor Yellow
    Write-Host "  [1] English"
    Write-Host "  [2] Francais"
    Write-Host "  [3] Espanol"
    Write-Host "  [4] Deutsch"
    $langChoice = Read-Host "Choice (1-4)"
    switch ($langChoice) {
        "1" { $script:CurrentLang = "en" }
        "2" { $script:CurrentLang = "fr" }
        "3" { $script:CurrentLang = "es" }
        "4" { $script:CurrentLang = "de" }
    }
    $script:t = @{}; foreach ($k in $i18n.en.Keys) { $script:t[$k] = $i18n.en[$k] }
    if ($script:CurrentLang -ne "en") {
        foreach ($k in $i18n[$script:CurrentLang].Keys) { $script:t[$k] = $i18n[$script:CurrentLang][$k] }
    }
}

# Point d'entree CLI (sans menu) si -Action est fourni — utile pour automation / fenetre bench
if ($Action -eq "install" -or $Action -eq "install-context") { Install-Optimizations -Mode "context"; Exit }
if ($Action -eq "install-speed") { Install-Optimizations -Mode "speed"; Exit }
if ($Action -eq "restore") { Restore-Defaults; Exit }
if ($Action -eq "status")  { Show-Status; Exit }
if ($Action -eq "bench")   { Run-Benchmark; Stop-BenchmarkHost }
if ($Action -eq "health")  { Invoke-HealthCheck; Exit }
if ($Action -eq "smart")   { Invoke-SmartGpuPreset; Exit }

# Boucle menu interactive (affichage + choix 1-5 / Q) — aucune action systeme tant que l'usager n'a pas choisi
do {
    Initialize-MenuConsole
    # Here-string LITERAL (@' '@) : les backticks de l'ASCII art ne sont pas interpretes par PowerShell
    Write-Host @'
        ____
      .'    '.     _ _                        _____ _
     /  o  o  \   | | | __ _ _ __ ___   __ _ |_   _| |_ _ __ _ __   ___
    |    --    |  | | |/ _` | '_ ` _ \ / _` |  | | | | | '__| '_ \ / _ \
     \        /   | | | (_| | | | | | | (_| |  | | | |_| |  | |_) | (_) |
      '.____.'    |_|_|\__,_|_| |_| |_|\__,_|  \_/  \__,_|  |_.__/ \___/
      Multi-Language 1-Click Optimizer (RTX 30 / 40 / 50 Series)
'@ -ForegroundColor Cyan
    Write-Host "      by Masterm3u  -  github.com/Masterm3u/Ollama-Turbo-RTX" -ForegroundColor DarkGray
    Write-Host "      Star the repo  |  buymeacoffee.com/masterm3u" -ForegroundColor DarkYellow

    Show-Status
    Show-Menu

    $choice = Read-Host $t.prompt_choice

    switch ($choice) {
        "1" { Install-Optimizations -Mode "context"; Pause }
        "2" { Install-Optimizations -Mode "speed"; Pause }
        "3" { Restore-Defaults; Pause }
        "4" { Start-BenchmarkWindow; Pause }
        "5" { Select-Language }
        "6" { Invoke-HealthCheck; Pause }
        "7" { Invoke-SmartGpuPreset; Pause }
        "8" { Invoke-WorkflowPreset; Pause }
        "9" { Invoke-HistoryRestore; Pause }
        "Q" { Exit }
        "q" { Exit }
        default { Write-Warning "Invalid option." }
    }
} while ($choice -ne "Q" -and $choice -ne "q")
