# Ollama Turbo RTX

Optimiseur 1-clic pour [Ollama](https://ollama.com) sur GPU NVIDIA RTX (séries 30 / 40 / 50).

## Fonctionnalités

- **Turbo Contexte (FA + Q8)** — Flash Attention + cache KV `q8_0` (~50 % VRAM contexte)
- **Turbo Vitesse Pure (FA seul)** — Flash Attention, KV FP16
- **Rollback** — restauration des réglages d’usine
- **Benchmark comparatif** — Stock vs Vitesse Pure vs Contexte (fenêtre admin séparée)

## Prérequis

- Windows 10 / 11
- GPU NVIDIA compatible
- [Ollama](https://ollama.com/download) installé
- Lancer en **Administrateur** (variables d’environnement Machine)

## Utilisation

Double-clic sur `Ollama-Turbo-RTX.bat`, ou :

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Ollama-Turbo-RTX.ps1
```

## Auteur

Compte GitHub : [Masterm3u](https://github.com/Masterm3u)

## Licence

MIT
