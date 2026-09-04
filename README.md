# Spotify Ad Mute (Windows)

Questo script controlla Spotify in background e mette in muto solo la sessione audio di Spotify quando rileva una pubblicità.

## Come funziona

- legge lo stato di riproduzione di Spotify tramite SMTC (System Media Transport Controls)
- riconosce una pubblicità quando artista o album non vengono valorizzati da Spotify
- mette in muto solo il processo `spotify.exe` tramite Core Audio / WASAPI
- riporta il volume normale quando la riproduzione torna a un brano normale

In pratica, il programma non silenzia tutto il sistema, ma solo la sessione audio di Spotify.

## Requisiti

- Windows 10/11
- Spotify installato e in esecuzione
- Python 3.11 o superiore
- dipendenze installate nella virtual environment del progetto

```powershell
cd "C:\Users\franc\Desktop\automute\automute_W11"
.\venv\Scripts\python.exe -m pip install -r .\requirements.txt
```

## Avvio via PowerShell

Da dentro la cartella del progetto:

```powershell
cd "C:\Users\franc\Desktop\automute\automute_W11"
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\start_automute.ps1
```

Il launcher usa solo la cartella `venv` del progetto e la crea se non esiste. Per un avvio diretto:

```powershell
cd "C:\Users\franc\Desktop\automute\automute_W11"
.\venv\Scripts\python.exe .\spotify_ad_mute.py
```

## File principali

- `spotify_ad_mute.py` — logica principale dell’applicazione
- `start_automute.ps1` — script che avvia Python usando la venv del progetto
- `requirements.txt` — eventuali dipendenze del progetto

## Problemi comuni

### 1. Errore di importazione di `winrt` o `pycaw`

Se appare un messaggio tipo `ModuleNotFoundError` o `No module named ...`, significa che la venv non contiene le dipendenze.

Esegui:

```powershell
cd "C:\Users\franc\Desktop\automute\automute_W11"
.\venv\Scripts\python.exe -m pip install -r requirements.txt
```

### 2. Il programma non rileva Spotify

Controlla che:

- Spotify sia davvero aperto
- la sessione multimediale di Spotify sia attiva
- non sia in fase di aggiornamento o chiusura

Il programma usa le API di Windows per leggere lo stato di riproduzione, quindi dipende dal supporto SMTC di Spotify.

### 3. Nessun audio viene messo in muto

Verifica che il processo `spotify.exe` sia effettivamente in esecuzione e che l’audio della sessione sia gestito da Windows Audio Session API.

Se Spotify è stato chiuso o riavviato, può servire riavviare lo script.

### 4. L’esecuzione viene bloccata da Policy PowerShell

Se PowerShell blocca l’esecuzione dello script, prova:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned
```

Poi riavvia:

```powershell
.\start_automute.ps1
```

## Nota importante

Questo tool si basa su segnali di Windows e su come Spotify espone lo stato multimediale. In alcuni casi, soprattutto con versioni del client o comportamenti del sistema diversi, la rilevazione può essere meno stabile.

## Uscita

Per terminare il programma, premi:

```powershell
Ctrl + C
```
