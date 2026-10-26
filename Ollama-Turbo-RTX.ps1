param (
    [string]$Action = "",
    [string]$Lang = ""
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Dimensionnement provisoire (le fit final = buffer verrouille apres dessin du menu)
try {
    $rawUI = $Host.UI.RawUI
    $newSize = New-Object System.Management.Automation.Host.Size(110, 55)
    $rawUI.BufferSize = $newSize
    $rawUI.WindowSize = $newSize
    [Console]::SetWindowPosition(0, 0)
} catch {}

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
        opt_q          = "  [Q] Exit"
        prompt_choice  = "Enter your choice (1-5 or Q)"
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
        opt_q          = "  [Q] Quitter"
        prompt_choice  = "Entrez votre choix (1-5 ou Q)"
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
        prompt_choice  = "Introduce tu opcion (1-5 o Q)"
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
        prompt_choice  = "Eingabe (1-5 oder Q)"
    }
}

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
$t = $i18n[$CurrentLang]

function Get-ScriptPath {
    if ($PSCommandPath) { return $PSCommandPath }
    if ($MyInvocation.PSCommandPath) { return $MyInvocation.PSCommandPath }
    if ($PSScriptRoot -and $MyInvocation.MyCommand.Name) {
        return (Join-Path $PSScriptRoot $MyInvocation.MyCommand.Name)
    }
    return $null
}

function Test-IsAdmin {
    return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

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

function Sync-OllamaProcessEnv {
    # Les enfants (ollama.exe) heritent du process parent, PAS du registre Machine.
    # Il faut donc synchroniser aussi $env: apres SetEnvironmentVariable Machine.
    param(
        [AllowNull()][string]$FlashAttention,
        [AllowNull()][string]$KvCacheType,
        [AllowNull()][string]$HostBind = "127.0.0.1:11434"
    )

    if ([string]::IsNullOrEmpty($FlashAttention)) {
        [System.Environment]::SetEnvironmentVariable('OLLAMA_FLASH_ATTENTION', $null, 'Machine')
        Remove-Item Env:\OLLAMA_FLASH_ATTENTION -ErrorAction SilentlyContinue
    } else {
        [System.Environment]::SetEnvironmentVariable('OLLAMA_FLASH_ATTENTION', $FlashAttention, 'Machine')
        $env:OLLAMA_FLASH_ATTENTION = $FlashAttention
    }

    if ([string]::IsNullOrEmpty($KvCacheType)) {
        [System.Environment]::SetEnvironmentVariable('OLLAMA_KV_CACHE_TYPE', $null, 'Machine')
        Remove-Item Env:\OLLAMA_KV_CACHE_TYPE -ErrorAction SilentlyContinue
    } else {
        [System.Environment]::SetEnvironmentVariable('OLLAMA_KV_CACHE_TYPE', $KvCacheType, 'Machine')
        $env:OLLAMA_KV_CACHE_TYPE = $KvCacheType
    }

    if ([string]::IsNullOrEmpty($HostBind)) {
        [System.Environment]::SetEnvironmentVariable('OLLAMA_HOST', $null, 'Machine')
        Remove-Item Env:\OLLAMA_HOST -ErrorAction SilentlyContinue
    } else {
        [System.Environment]::SetEnvironmentVariable('OLLAMA_HOST', $HostBind, 'Machine')
        $env:OLLAMA_HOST = $HostBind
    }
}

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

function Stop-OllamaSilent {
    # Arret silencieux : app + serveur + runners CUDA orphelins (llama-server).
    # Sans tuer llama-server, la VRAM reste occupee et le bench tombe en 500 OOM.
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

function Start-OllamaSilent {
    # Demarrage transparent : UI masquee (hidden / --hide) + pas de fenetre console.
    # --fast-startup evite les pop-ups de mise a jour au lancement.
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

function Get-ActiveTurboMode {
    $fa = [System.Environment]::GetEnvironmentVariable('OLLAMA_FLASH_ATTENTION', 'Machine')
    $kv = [System.Environment]::GetEnvironmentVariable('OLLAMA_KV_CACHE_TYPE', 'Machine')
    if ($fa -eq '1' -and $kv -eq 'q8_0') { return "context" }
    if ($fa -eq '1') { return "speed" }
    return "stock"
}

function Show-Status {
    Write-Host "`n========================================================" -ForegroundColor DarkGray
    Write-Host $t.status_title -ForegroundColor Cyan
    Write-Host "========================================================" -ForegroundColor DarkGray

    $fa = [System.Environment]::GetEnvironmentVariable('OLLAMA_FLASH_ATTENTION', 'Machine')
    $kv = [System.Environment]::GetEnvironmentVariable('OLLAMA_KV_CACHE_TYPE', 'Machine')
    $hostBind = [System.Environment]::GetEnvironmentVariable('OLLAMA_HOST', 'Machine')
    $mode = Get-ActiveTurboMode

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
    Write-Host $t.opt_q
    Write-Host ""
}

function Install-Optimizations {
    param(
        [ValidateSet("context", "speed")]
        [string]$Mode = "context"
    )

    Check-Admin
    Write-Host "`n$($t.gpu_detect)" -ForegroundColor Cyan
    $gpu = Get-CimInstance Win32_VideoController | Where-Object { $_.Name -like "*NVIDIA*" -and $_.Name -notlike "*Audio*" } | Select-Object -First 1

    if (-not $gpu) {
        Write-Error $t.gpu_none
        return
    }

    $vramGB = [math]::Round($gpu.AdapterRAM / 1GB, 1)
    if ($vramGB -le 4) {
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
        Sync-OllamaProcessEnv -FlashAttention '1' -KvCacheType 'q8_0' -HostBind '127.0.0.1:11434'
        Write-Host $t.fa_set -ForegroundColor Green
        Write-Host $t.kv_set -ForegroundColor Green
    } else {
        Sync-OllamaProcessEnv -FlashAttention '1' -KvCacheType $null -HostBind '127.0.0.1:11434'
        Write-Host $t.fa_set -ForegroundColor Green
        Write-Host $t.kv_clear -ForegroundColor Yellow
    }
    Write-Host $t.host_set -ForegroundColor Green

    Write-Host $t.vars_applied -ForegroundColor Green
    Restart-Ollama -WaitReady
    Show-Status
}

function Restore-Defaults {
    Check-Admin
    Write-Host "`n$($t.revert_title)" -ForegroundColor Cyan
    Sync-OllamaProcessEnv -FlashAttention $null -KvCacheType $null -HostBind $null

    Write-Host $t.revert_ok -ForegroundColor Yellow
    Restart-Ollama -WaitReady
    Show-Status
}

function Start-BenchmarkWindow {
    $scriptPath = Get-ScriptPath
    if (-not $scriptPath -or -not (Test-Path $scriptPath)) {
        Write-Warning $t.bench_window_fail
        return
    }

    # Toujours -Verb RunAs : Start-Process SANS RunAs ne garantit PAS l'elevation
    # (meme depuis un parent admin, selon le contexte / Cursor / .bat).
    # Sans -NoExit : la fenetre disparait a la fin du bench.
    # ArgumentList en tableau = parsing fiable avec UAC (chemins avec espaces OK).
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

function Set-ConsoleSizeSafe {
    param(
        [int]$Width = 110,
        [int]$Height = 45,
        [switch]$LockBuffer  # buffer = fenetre : empêche le scroll (titre reste visible sous WT)
    )
    try {
        $maxW = [Console]::LargestWindowWidth
        $maxH = [Console]::LargestWindowHeight
        if ($maxW -lt 40) { $maxW = 120 }
        if ($maxH -lt 20) { $maxH = 60 }

        $w = [math]::Min($Width, $maxW)
        $h = [math]::Min($Height, $maxH)
        if ($w -lt 80) { $w = [math]::Min(80, $maxW) }
        if ($h -lt 30) { $h = [math]::Min(30, $maxH) }

        # 1) agrandir buffer  2) fenetre  3) optionnel: buffer = fenetre (plus de scrollbar)
        $growW = [math]::Max([Console]::BufferWidth, $w)
        $growH = [math]::Max([Console]::BufferHeight, $h)
        [Console]::SetBufferSize($growW, $growH)
        [Console]::SetWindowSize($w, $h)
        if ($LockBuffer) {
            [Console]::SetBufferSize($w, $h)
        }
        [Console]::SetWindowPosition(0, 0)
    } catch {
        try {
            $raw = $Host.UI.RawUI
            $mw = [math]::Min($Width, $raw.MaxWindowSize.Width)
            $mh = [math]::Min($Height, $raw.MaxWindowSize.Height)
            $bw = [math]::Max($Width, $mw)
            $bh = [math]::Max($Height, $mh)
            $raw.BufferSize = New-Object System.Management.Automation.Host.Size ($bw, $bh)
            $raw.WindowSize = New-Object System.Management.Automation.Host.Size ($mw, $mh)
            if ($LockBuffer) {
                $raw.BufferSize = New-Object System.Management.Automation.Host.Size ($mw, $mh)
            }
            $raw.WindowPosition = New-Object System.Management.Automation.Host.Coordinates 0, 0
        } catch {}
    }
}

function Show-ConsoleFromTop {
    # Hauteur = menu entier + prompt ; buffer verrouille = titre ASCII toujours visible
    try {
        $usedLines = [Console]::CursorTop + 5
        if ($usedLines -lt 50) { $usedLines = 50 }
        Set-ConsoleSizeSafe -Width 110 -Height $usedLines -LockBuffer
        [Console]::SetWindowPosition(0, 0)
        try {
            $Host.UI.RawUI.WindowPosition = New-Object System.Management.Automation.Host.Coordinates 0, 0
        } catch {}
    } catch {
        try {
            $raw = $Host.UI.RawUI
            $used = [math]::Max($raw.CursorPosition.Y + 5, 50)
            Set-ConsoleSizeSafe -Width 110 -Height $used -LockBuffer
            $raw.WindowPosition = New-Object System.Management.Automation.Host.Coordinates 0, 0
        } catch {}
    }
}

function Initialize-MenuConsole {
    # Grande fenetre provisoire ; fit exact + LockBuffer apres le dessin
    try { $host.UI.RawUI.WindowTitle = "Ollama Turbo RTX" } catch {}
    Set-ConsoleSizeSafe -Width 110 -Height 55 -LockBuffer
    Clear-Host
    try {
        [Console]::SetCursorPosition(0, 0)
        [Console]::SetWindowPosition(0, 0)
    } catch {}
}

function Initialize-BenchConsole {
    # Bench : partir du haut (pas de maximize = pas de bande noire inutile)
    try { $host.UI.RawUI.WindowTitle = "Ollama Turbo Benchmark [ADMIN]" } catch {}
    Set-ConsoleSizeSafe -Width 120 -Height 45
    # Buffer profond pour scroller l'historique pendant le bench, vue au debut
    try {
        [Console]::SetBufferSize(120, [math]::Max(3000, [Console]::BufferHeight))
        [Console]::SetWindowPosition(0, 0)
    } catch {}
    Clear-Host
    try {
        [Console]::SetCursorPosition(0, 0)
        [Console]::SetWindowPosition(0, 0)
    } catch {}
}

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

    function Execute-3Passes {
        param([string]$PhaseName)
        Write-Host "`n[*] $PhaseName (3 passes en cours)..." -ForegroundColor Yellow
        Write-Host "  [*] Cache bust: New-HeavyStressPrompt() + keep_alive=0 (attention O(N^2) reelle)" -ForegroundColor DarkGray

        # Warm-up CUDA / poids avec prompt lourd unique, puis purge
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

    # =========================================================================
    # PHASE 1/3 : STOCK
    # =========================================================================
    Write-Host "`n>>> ETAPE 1/3 : STOCK (aucune optimisation)..." -ForegroundColor Cyan
    Sync-OllamaProcessEnv -FlashAttention $null -KvCacheType $null -HostBind '127.0.0.1:11434'
    Clear-OllamaGpuRunners
    Restart-Ollama -WaitReady
    $resStock = Execute-3Passes -PhaseName "Mesure Mode STOCK"

    # =========================================================================
    # PHASE 2/3 : TURBO VITESSE PURE (FA seul)
    # =========================================================================
    Write-Host "`n>>> ETAPE 2/3 : TURBO VITESSE PURE (Flash Attention seul)..." -ForegroundColor Cyan
    Sync-OllamaProcessEnv -FlashAttention '1' -KvCacheType $null -HostBind '127.0.0.1:11434'
    Clear-OllamaGpuRunners
    Restart-Ollama -WaitReady
    $resSpeed = Execute-3Passes -PhaseName "Mesure Mode TURBO VITESSE PURE"

    # =========================================================================
    # PHASE 3/3 : TURBO CONTEXTE (FA + Q8)
    # =========================================================================
    Write-Host "`n>>> ETAPE 3/3 : TURBO CONTEXTE (Flash Attention + Q8)..." -ForegroundColor Cyan
    Sync-OllamaProcessEnv -FlashAttention '1' -KvCacheType 'q8_0' -HostBind '127.0.0.1:11434'
    Clear-OllamaGpuRunners
    Restart-Ollama -WaitReady
    $resContext = Execute-3Passes -PhaseName "Mesure Mode TURBO CONTEXTE"

    # =========================================================================
    # RESTAURATION
    # =========================================================================
    Write-Host "`n[*] Restauration de l'etat initial de votre machine..." -ForegroundColor Cyan
    Sync-OllamaProcessEnv -FlashAttention $origFA -KvCacheType $origKV -HostBind $origHost
    Restart-Ollama -WaitReady

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

    $sepLine = "=" * 82
    $subLine = "-" * 82

    Write-Host ""
    Write-Host $sepLine -ForegroundColor DarkGray
    Write-Host " RAPPORT DE PERFORMANCE OLLAMA (Modele : $testModel | Contexte : $benchCtx tokens)" -ForegroundColor Cyan
    Write-Host $sepLine -ForegroundColor DarkGray
    Write-Host (" {0,-26} | {1,18} | {2,14} | {3,13} " -f "CONFIGURATION", "GENERATION (t/s)", "GAIN VITESSE", "GAIN VRAM") -ForegroundColor Yellow
    Write-Host $subLine -ForegroundColor DarkGray

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

    $saveChoice = Read-HostWithTimeout -Prompt $t.bench_save_prompt -TimeoutSec 20 -DefaultValue "N"
    if ($saveChoice -match '^(o|oui|y|yes|s|si|j|ja)') {
        $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        $desktopPath = [Environment]::GetFolderPath("Desktop")
        $filePath = Join-Path $desktopPath "Ollama_Turbo_Comparatif.txt"

        $report = @"
================================================================================
 RAPPORT DE PERFORMANCE OLLAMA : STOCK vs TURBO
 Date     : $timestamp
 Modele   : $testModel
 Contexte : $benchCtx tokens
================================================================================
 CONFIGURATION              GENERATION (Tokens/s)   GAIN VITESSE    GAIN VRAM
--------------------------------------------------------------------------------
 [Stock] Par defaut                 $($resStock.Eval) t/s       (Reference)      Aucun (100%)
 [2] Turbo Vitesse (FA)             $($resSpeed.Eval) t/s        $gainSpeedStr          Aucun (100%)
 [1] Turbo Contexte (FA + Q8)       $($resContext.Eval) t/s        $gainCtxStr          -50 % VRAM
================================================================================
 RECOMMANDATION :
 -> Meilleure configuration detectee : $bestMode
================================================================================
"@
        [System.IO.File]::WriteAllText($filePath, $report, [System.Text.Encoding]::UTF8)
        Write-Host "`n[OK] Rapport sauvegarde : $filePath" -ForegroundColor Green
        Start-Process notepad.exe -ArgumentList "`"$filePath`""
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
    $script:t = $i18n[$script:CurrentLang]
}

if ($Action -eq "install" -or $Action -eq "install-context") { Install-Optimizations -Mode "context"; Exit }
if ($Action -eq "install-speed") { Install-Optimizations -Mode "speed"; Exit }
if ($Action -eq "restore") { Restore-Defaults; Exit }
if ($Action -eq "status")  { Show-Status; Exit }
if ($Action -eq "bench")   { Run-Benchmark; Stop-BenchmarkHost }

do {
    Initialize-MenuConsole
    Write-Host @"
   ___  _ _                        _____            _           
  / _ \| | |                      |_   _|          | |          
 / / \ \ | | __ _ _ __ ___   __ _   | |_   _ _ __  | |__   ___  
 | | | | | |/ _` | '_ ` _ \ / _` |  | | | | | '__| | '_ \ / _ \ 
 \ \_/ / | | (_| | | | | | | (_| |  | | |_| | |    | |_) | (_) |
  \___/|_|_|\__,_|_| |_| |_|\__,_|  \_/\__,_|_|    |_.__/ \___/ 
      Multi-Language 1-Click Optimizer (RTX 30 / 40 / 50 Series)
"@ -ForegroundColor Cyan

    Show-Status
    Show-Menu

    # Hauteur = contenu exact ; vue forcee en haut pour voir le titre ASCII
    Show-ConsoleFromTop

    $choice = Read-Host $t.prompt_choice

    switch ($choice) {
        "1" { Install-Optimizations -Mode "context"; Pause }
        "2" { Install-Optimizations -Mode "speed"; Pause }
        "3" { Restore-Defaults; Pause }
        "4" { Start-BenchmarkWindow; Pause }
        "5" { Select-Language }
        "Q" { Exit }
        "q" { Exit }
        default { Write-Warning "Invalid option." }
    }
} while ($choice -ne "Q" -and $choice -ne "q")
