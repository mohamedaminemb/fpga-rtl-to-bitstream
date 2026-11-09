# FPGA RTL to Bitstream

[![VHDL Simulation](https://github.com/mohamedaminemb/fpga-rtl-to-bitstream/actions/workflows/simulation.yml/badge.svg?branch=main)](https://github.com/mohamedaminemb/fpga-rtl-to-bitstream/actions/workflows/simulation.yml)

Conception de modules numériques en VHDL et construction progressive d’un flot FPGA, de la vérification RTL à la génération du bitstream.

Le dépôt rassemble les sources RTL, des testbenches auto-vérifiants, une régression Python et des tests structurés avec VUnit.

## État actuel

- **16 modules RTL**, dont un module d’intégration UART avec FIFO
- **17 testbenches dans la régression GHDL**, exécutés dans 18 configurations
- **3 testbenches VUnit**, totalisant 42 tests :
  - 18 tests ALU sur les largeurs 1 et 4
  - 16 tests FIFO sur les profondeurs 1, 3 et 4, selon les scénarios
  - 8 tests d’intégration UART avec FIFO : écho, trafic consécutif, débordement et récupération après reset
- **4 758 vérifications dans les tests de composants de la régression GHDL**
- **256 octets pseudo-aléatoires vérifiés en bouclage UART**
- **4 octets consécutifs vérifiés dans le système d’écho UART avec FIFO**

Les deux suites ont réussi localement. Le badge indique le résultat du workflow publié sur la branche `main`.

La synthèse, l’analyse de timing, la génération du bitstream et la validation sur carte restent à réaliser.

## Prérequis

- Python 3.12 : version utilisée pour le développement
- GHDL avec prise en charge de VHDL-2008
- VUnit 4.7.1
- GTKWave, facultatif, pour examiner les chronogrammes

L’environnement de développement utilise Ubuntu 24.04 LTS et GHDL 4.1.0.

### Installer les dépendances Python

Depuis la racine du dépôt :

```bash
python3 -m venv .venv
.venv/bin/python -m pip install -r requirements-dev.txt
```

Le fichier `requirements-dev.txt` fixe la version de VUnit :

```text
vunit_hdl==4.7.1
```

L’environnement `.venv` est local et exclu du dépôt.

## Organisation du dépôt

```text
fpga-rtl-to-bitstream/
├── .github/
│   └── workflows/
│       └── simulation.yml
├── .gitignore
├── README.md
├── requirements-dev.txt
├── vhdl_ls.toml
├── rtl/
│   ├── mux21.vhd
│   ├── adder_sub.vhd
│   ├── reg_en.vhd
│   ├── counter_en.vhd
│   ├── clock_enable.vhd
│   ├── edge_detector.vhd
│   ├── sync_2ff.vhd
│   ├── debouncer.vhd
│   ├── button_conditioner.vhd
│   ├── sequence_detector.vhd
│   ├── traffic_light_controller.vhd
│   ├── fifo_sync.vhd
│   ├── uart_tx.vhd
│   ├── uart_rx.vhd
│   ├── uart_echo.vhd
│   └── alu.vhd
├── tb/
│   ├── tb_mux21.vhd
│   ├── tb_adder_sub.vhd
│   ├── tb_reg_en.vhd
│   ├── tb_counter_en.vhd
│   ├── tb_clock_enable.vhd
│   ├── tb_edge_detector.vhd
│   ├── tb_sync_2ff.vhd
│   ├── tb_debouncer.vhd
│   ├── tb_button_conditioner.vhd
│   ├── tb_sequence_detector.vhd
│   ├── tb_traffic_light_controller.vhd
│   ├── tb_fifo_sync.vhd
│   ├── tb_uart_tx.vhd
│   ├── tb_uart_rx.vhd
│   ├── tb_uart_loopback.vhd
│   ├── tb_uart_echo.vhd
│   ├── tb_alu.vhd
│   └── vunit/
│       ├── tb_alu_vunit.vhd
│       ├── tb_fifo_sync_vunit.vhd
│       └── tb_uart_echo_vunit.vhd
└── scripts/
    ├── run_tests.py
    └── run_vunit.py
```

Le bouclage UART instancie directement le TX et le RX dans son testbench. Il n’existe pas de module `rtl/uart_loopback.vhd`.

## Exécuter les tests

### Régression GHDL

```bash
.venv/bin/python scripts/run_tests.py
```

Message final attendu :

```text
All 17 testbenches passed.
```

Le script analyse les sources, élabore les testbenches et lance les simulations avec `--assert-level=error`.

- `source_overrides` définit les dépendances du bouclage UART et du système `uart_echo`.
- `simulation_options` définit les configurations supplémentaires.
- L’ALU est exécutée sur 4 bits puis sur 1 bit.
- Le script s’arrête au premier échec.

### Tests VUnit

Lister les tests :

```bash
.venv/bin/python scripts/run_vunit.py --list
```

Exécuter les 42 tests :

```bash
.venv/bin/python scripts/run_vunit.py
```

Exécuter uniquement les tests FIFO :

```bash
.venv/bin/python scripts/run_vunit.py 'lib.tb_fifo_sync_vunit.*'
```

Exécuter uniquement les tests ALU :

```bash
.venv/bin/python scripts/run_vunit.py 'lib.tb_alu_vunit.*'
```

Exécuter uniquement les tests d’écho UART :

```bash
.venv/bin/python scripts/run_vunit.py 'lib.tb_uart_echo_vunit.*'
```

Exécuter un scénario précis :

```bash
.venv/bin/python scripts/run_vunit.py \
  'lib.tb_fifo_sync_vunit.depth_3.wraparound_with_remaining_data'
```

Après activation de l’environnement, les mêmes commandes peuvent utiliser `python` :

```bash
source .venv/bin/activate
python scripts/run_vunit.py
```

L’activation doit être renouvelée dans chaque nouveau terminal.

### Rapport de tests VUnit

Générer un rapport XML compatible avec les outils xUnit/JUnit :

```bash
mkdir -p reports
.venv/bin/python scripts/run_vunit.py \
  --xunit-xml reports/vunit_results.xml
```

Le fichier `reports/vunit_results.xml` contient le bilan de la suite, les noms des tests, leurs configurations, leurs durées d’exécution et les sorties des simulations.

Le champ `time` d’un test représente sa durée d’exécution sur l’ordinateur, en secondes. Les instants exprimés en nanosecondes dans le journal correspondent au temps simulé.

Le rapport concerne uniquement les 42 tests VUnit ; il n’inclut pas les testbenches lancés par `run_tests.py` et ne mesure pas la couverture du RTL.

Le dossier `reports/` est généré localement et exclu de Git.

### Codes de retour

Après une commande :

```bash
echo $?
```

Un code `0` indique une réussite. Un code non nul indique un échec.

## Intégration continue

Le workflow **VHDL Simulation** exécute :

1. La régression GHDL existante.
2. Les tests VUnit de l’ALU, de la FIFO et du système d’écho UART.

Il est configuré pour les événements `push`, `pull_request` et le lancement manuel avec **Run workflow**.

Sur Ubuntu 24.04, il récupère le dépôt, installe GHDL, crée un environnement Python et installe les dépendances depuis `requirements-dev.txt`.

`VUNIT_SIMULATOR=ghdl` sélectionne explicitement GHDL pour VUnit.

Le workflow possède un accès en lecture au contenu du dépôt et une limite d’exécution de 10 minutes.

Les résultats sont disponibles dans l’onglet [Actions](https://github.com/mohamedaminemb/fpga-rtl-to-bitstream/actions/workflows/simulation.yml).

Le workflow est configuré pour générer le rapport VUnit puis le conserver dans un artifact nommé `vunit-test-report` pendant 14 jours.

L’étape de dépôt utilise `if: always()` pour tenter de conserver le rapport même si une étape précédente a échoué. Cela ne masque pas l’échec des tests. Si aucun XML n’a été généré, l’étape affiche un avertissement.

Pour télécharger le rapport, ouvrir une exécution du workflow, sélectionner sa page **Summary**, puis télécharger `vunit-test-report` dans la section **Artifacts**.

Le rapport local a été actualisé après la réussite des 42 tests VUnit. Le téléchargement des rapports a été validé lors d’une précédente exécution GitHub Actions ; la nouvelle suite doit également être validée après son push.


## Composants et vérification

Les nombres ci-dessous concernent uniquement la régression GHDL historique.

| Module | Fonction | Configuration testée | Vérifications |
|---|---|---|---:|
| `mux21` | Multiplexeur combinatoire | Entrées binaires | 8 |
| `adder_sub` | Additionneur/soustracteur non signé | `N = 8` | 4 |
| `reg_en` | Registre avec reset et enable | `WIDTH = 8` | 7 |
| `counter_en` | Compteur avec reset et enable | `WIDTH = 3` | 14 |
| `clock_enable` | Autorisation périodique | `DIVISOR = 4` | 16 |
| `edge_detector` | Détecteur de montée | Entrée synchrone d’un bit | 10 |
| `sync_2ff` | Synchroniseur à deux bascules | Entrée d’un bit | 13 |
| `debouncer` | Filtre anti-rebond | `STABLE_CYCLES = 3` | 25 |
| `button_conditioner` | Traitement complet de bouton | `STABLE_CYCLES = 3` | 88 |
| `sequence_detector` | Détection de `1011` avec chevauchement | Flux binaire synchrone | 46 |
| `traffic_light_controller` | FSM temporisée | Durées `(3,4,2)` et `(1,1,1)` | 68 |
| `fifo_sync` | FIFO à lecture enregistrée | `WIDTH = 8`, `DEPTH = 4` | 93 |
| `uart_tx` | Émetteur UART 8N1 | `CLKS_PER_BIT = 4` | 180 |
| `uart_rx` | Récepteur UART 8N1 | `CLKS_PER_BIT = 8` | 26 |
| `alu` | Unité arithmétique et logique | Largeurs 1 et 4 | 4 160 |

Les deux tests d’intégration ajoutent le bouclage UART de 256 octets et l’écho UART avec FIFO de 4 octets consécutifs. Ces nombres d’octets sont distincts des vérifications de composants du tableau et des tests VUnit.

### Logique combinatoire et séquentielle

Les premiers composants couvrent la sélection de données, les calculs non signés, la mémorisation, le comptage et la génération d’autorisations périodiques.

Les modules séquentiels utilisent un reset synchrone actif à l’état haut.

Les tests comprennent des cas de maintien, de débordement et de priorité du reset.

### Traitement de bouton

```text
button_in → sync_2ff → debouncer → edge_detector → press_pulse
                          │
                          └──────────────────────→ button_clean
```

Le filtre accepte une nouvelle valeur après un nombre paramétrable d’observations consécutives. Le détecteur produit une impulsion lors d’une montée de la valeur filtrée.

Les tests couvrent les appuis, le maintien, le relâchement et des rebonds numériques simulés.

Une entrée maintenue haute après reset est interprétée comme un appui une fois synchronisée et filtrée.

### Machines à états

`sequence_detector` reconnaît `1011` avec chevauchement :

```text
Entrée    : 1 0 1 1 0 1 1
Détection : 0 0 0 1 0 0 1
```

Les tests couvrent les préfixes incorrects, les suffixes utiles et l’effacement d’une reconnaissance partielle par reset.

`traffic_light_controller` réalise la rotation rouge, vert, orange avec des durées paramétrables. Deux instances vérifient les durées normales et le cas limite d’un cycle par état.

## FIFO synchrone

`fifo_sync` utilise une mémoire, deux pointeurs circulaires et un compteur d’occupation.

Les demandes sont acceptées selon l’occupation avant le front montant :

| État avant deux demandes simultanées | Écriture | Lecture |
|---|---|---|
| Vide | Acceptée | Refusée |
| Occupation intermédiaire | Acceptée | Acceptée |
| Pleine | Refusée | Acceptée |

La sortie de lecture est enregistrée et conserve sa valeur sans lecture acceptée.

Le reset remet les pointeurs, l’occupation et la sortie à zéro sans effacer le tableau mémoire.

### Vérification FIFO avec VUnit

La largeur des données est fixée à 8 bits dans les configurations actuelles.

| Scénario | Profondeurs | Tests |
|---|---|---:|
| `reset_empty` | 1, 3, 4 | 3 |
| `fill_reject_write_and_drain` | 1, 3, 4 | 3 |
| `simultaneous_when_full` | 1, 3, 4 | 3 |
| `simultaneous_when_empty` | 1, 3, 4 | 3 |
| `simultaneous_when_partial` | 3, 4 | 2 |
| `wraparound_with_remaining_data` | 3, 4 | 2 |
| **Total** | | **16** |

Les tests vérifient :

- Le reset initial.
- Le remplissage et le vidage.
- Les drapeaux `empty` et `full`.
- Le refus d’écriture à plein sans écrasement des données.
- Le refus de lecture à vide avec conservation de la sortie.
- Les demandes simultanées à vide, à plein et avec occupation intermédiaire.
- L’ordre des données après retour des pointeurs.

La profondeur 1 couvre le cas minimal. La profondeur 3 vérifie un retour circulaire pour une taille non puissance de deux.

Les scénarios nécessitant une occupation intermédiaire sont configurés uniquement pour les profondeurs 3 et 4.

Le retour des pointeurs est vérifié indirectement par les données et les drapeaux observables. Pour `DEPTH = 3` :

```text
Écrire 1, 2, 3 → [1, 2, 3]
Lire 1 puis 2  → [3]
Écrire 4 et 5  → [3, 4, 5]
Lire           → 3, 4, 5
```

## UART TX/RX

Le format utilisé est 8N1 : start bas, huit bits LSB d’abord, stop haut.

Le TX copie l’octet lors de l’acceptation de `start`. Les demandes présentées uniquement pendant `busy` sont ignorées. `done` est activé après la durée complète du stop.

Le RX synchronise son entrée et échantillonne près du milieu des bits. Il exige actuellement un `CLKS_PER_BIT` pair, supérieur ou égal à 4.

Un stop correct produit `valid`. Un stop incorrect produit `frame_error` sans modifier le dernier octet valide.

Après une erreur de trame, l’état `WAIT_IDLE` attend le retour de la ligne au niveau haut avant une nouvelle réception.

### Bouclage UART

```text
Octet attendu → uart_tx → ligne série → uart_rx → Comparaison
```

Le test utilise une horloge commune et `CLKS_PER_BIT = 8` pour les deux modules.

Un LFSR de 16 bits, initialisé avec la graine fixe `0xACE1`, fournit 256 octets pseudo-aléatoires reproductibles.

Le moniteur compare les octets reçus et contrôle les événements de réception et de fin d’émission.

Les valeurs peuvent se répéter. Une marge de repos est insérée entre les trames.

## Écho UART avec FIFO

`uart_echo` assemble les modules `uart_rx`, `fifo_sync` et `uart_tx` pour renvoyer les octets reçus sans les modifier.

```text
Entrée rx → UART RX → FIFO 8 bits → UART TX → Sortie tx
                         ↑             ↑
                         └── Contrôleur┘
```

Les paramètres `CLKS_PER_BIT` et `FIFO_DEPTH` règlent respectivement la durée d’un bit UART et la capacité de stockage en octets.

L’écriture dans la FIFO est demandée lorsqu’un octet valide est disponible et que la FIFO n’est pas pleine.

Le contrôleur utilise quatre états :

| État | Fonction |
|---|---|
| `IDLE` | Attendre une FIFO non vide et un TX disponible |
| `LOAD` | Demander une lecture FIFO pendant un cycle |
| `SEND` | Demander l’émission de la donnée lue pendant un cycle |
| `WAIT_TX` | Attendre la fin de transmission avant de traiter la donnée suivante |

La lecture FIFO étant enregistrée, la demande d’émission intervient après la mise à jour de sa sortie.

Si un octet valide arrive alors que la FIFO est pleine, cet octet est refusé et `overflow` est mémorisé à l’état haut jusqu’au reset. La décision utilise l’état de la FIFO avant le front, même si une lecture est acceptée au même front.

La sortie `frame_error` du RX n’est pas exposée par cette première interface. Le RX ne produit pas `valid` pour une trame dont le stop est incorrect.

### Vérification de l’écho

`tb_uart_echo.vhd` génère les trames d’entrée et vérifie la sortie série directement, bit par bit, dans un processus indépendant.

Configuration testée :

- Période d’horloge : 10 ns.
- `CLKS_PER_BIT = 8`, soit 80 ns par bit.
- `FIFO_DEPTH = 4`.
- Quatre octets envoyés sans pause supplémentaire entre les trames : `0x00`, `0xFF`, `0xA6`, `0x3C`.

Les vérifications portent sur le repos après reset, les bits de start, les données dans l’ordre attendu, les bits de stop et l’absence de débordement signalé. Une surveillance de 800 ns après le dernier stop détecte un éventuel départ de trame supplémentaire pendant cette fenêtre.

Un délai maximal empêche le test de rester bloqué si un écho manque. La simulation validée se termine à 4 975 ns.

Ce test couvre une courte séquence nominale. Il ne valide pas encore la saturation de la FIFO, l’activation de `overflow`, les resets pendant le trafic ou un flux continu de durée arbitraire. Le contrôleur ajoute des cycles entre émissions ; une FIFO finie ne garantit donc pas l’absence de perte sous un trafic soutenu.

### Vérification de l’écho avec VUnit

`tb/vunit/tb_uart_echo_vunit.vhd` ajoute quatre scénarios indépendants. Les trames sont générées sur `rx` et les échos sont vérifiés directement sur `tx`, sans réutiliser le RX du projet comme décodeur de référence.

| Scénario | Profondeurs FIFO | Tests |
|---|---|---:|
| `single_byte` | 1, 3, 4 | 3 |
| `consecutive_bytes` | 1, 3, 4 | 3 |
| `overflow_sticky` | 1 | 1 |
| `reset_recovery` | 1 | 1 |
| **Total** | | **8** |

Les scénarios nominaux vérifient l’octet `0xA6`, puis une séquence de quatre octets `0xA6`, `0x00`, `0xFF`, `0x3C`. Le moniteur contrôle le start, les données et le stop, puis surveille l’absence de trame supplémentaire pendant 800 ns. Le processus principal vérifie également l’absence de débordement et impose une durée maximale d’attente.

`overflow_sticky` envoie des trames `0x55` consécutives jusqu’à observer un débordement, avec une limite de 128 octets. Après l’arrêt du trafic et une attente permettant de terminer les émissions, le test vérifie que `overflow` reste actif et que `tx` est au repos.

Le débit UART est identique à l’entrée et à la sortie pendant une trame. Les cycles supplémentaires du contrôleur entre émissions réduisent toutefois le débit moyen de sortie, ce qui permet de provoquer une saturation sous un trafic soutenu.

`reset_recovery` provoque un débordement, arrête le trafic, puis vérifie que l’indicateur ne s’efface pas avant le front montant de reset et s’efface après ce front. Un nouvel écho de `0xA6` vérifie la reprise des échanges.

Les scénarios de saturation ne comparent pas les données renvoyées pendant le débordement. La récupération est testée après l’arrêt du trafic ; l’interruption d’une trame en cours par reset reste à vérifier. Un watchdog de 200 us limite la durée de chaque simulation de ce testbench.

## ALU

L’ALU est combinatoire, paramétrable en largeur et non signée.

| `op` | Opération |
|---|---|
| `"000"` | Addition modulo `2^WIDTH` |
| `"001"` | Soustraction modulo `2^WIDTH` |
| `"010"` | ET logique |
| `"011"` | OU logique |
| `"100"` | OU exclusif |
| `"101"` | Décalage logique gauche de `a` |
| `"110"` | Décalage logique droite de `a` |
| `"111"` | Copie de `a` |

Les décalages portent sur un bit et insèrent un zéro. L’indicateur `zero` signale un résultat nul.

### Testbench exhaustif

`tb_alu.vhd` utilise un modèle de référence à base d’entiers.

| Largeur | Cas binaires | Vérifications |
|---|---:|---:|
| 4 bits | 2 048 | 4 096 |
| 1 bit | 32 | 64 |

Chaque cas vérifie le résultat et `zero`.

### Testbench VUnit

`tb/vunit/tb_alu_vunit.vhd` propose neuf scénarios :

- `addition`
- `subtraction_wrap`
- `addition_wrap`
- `logical_and`
- `logical_or`
- `logical_xor`
- `shift_left`
- `shift_right`
- `pass_a`

Chaque scénario s’exécute sur les largeurs 1 et 4, soit 18 tests, avec deux comparaisons par test.

Ces scénarios dirigés complètent le testbench exhaustif.

La détection d’échec a été vérifiée en modifiant temporairement un résultat attendu. Les deux configurations concernées ont échoué, puis les tests ont réussi après restauration.

## Organisation des tests VUnit

```text
run_vunit.py
    │
    ├── Enregistrement des sources
    ├── Définition des configurations
    └── Compilation et simulations avec GHDL
                │
                ▼
         Testbench VUnit
                │
                ├── Application des entrées au RTL
                ├── Attente de la mise à jour des sorties
                └── Comparaisons avec check_equal
```

Les paramètres Python sont transmis aux generics du testbench, puis aux generics du RTL.

Pour la FIFO, les entrées sont préparées au front descendant. Les opérations sont capturées au front montant, puis les sorties sont vérifiées après une attente de simulation de 1 ns.

Cette attente appartient uniquement au testbench.

## Simulations individuelles

Exemple pour la FIFO :

```bash
ghdl -a --std=08 rtl/fifo_sync.vhd tb/tb_fifo_sync.vhd
ghdl -e --std=08 tb_fifo_sync
ghdl -r --std=08 tb_fifo_sync --assert-level=error --vcd=fifo_sync.vcd
```

Exemple pour le bouclage UART :

```bash
ghdl -a --std=08 rtl/uart_tx.vhd rtl/uart_rx.vhd tb/tb_uart_loopback.vhd
ghdl -e --std=08 tb_uart_loopback
ghdl -r --std=08 tb_uart_loopback --assert-level=error --vcd=uart_loopback.vcd
```

Exemple pour l’écho UART avec FIFO :

```bash
ghdl -a --std=08 rtl/uart_rx.vhd rtl/fifo_sync.vhd rtl/uart_tx.vhd rtl/uart_echo.vhd tb/tb_uart_echo.vhd
ghdl -e --std=08 tb_uart_echo
ghdl -r --std=08 tb_uart_echo --assert-level=error --vcd=uart_echo.vcd
```

Pour `button_conditioner`, analyser d’abord ses composants `sync_2ff`, `debouncer` et `edge_detector`.

Après génération d’une trace :

```bash
gtkwave uart_loopback.vcd
```

Les testbenches VUnit sont lancés avec `run_vunit.py`, qui gère leurs bibliothèques et leurs configurations.

## Configuration de l’éditeur

Le fichier `vhdl_ls.toml` configure l’association des sources aux bibliothèques pour l’analyse dans l’éditeur.

Cette configuration est indépendante des bibliothèques de compilation gérées par GHDL et VUnit.

## Limites de vérification

Les vérifications, les scénarios et les octets transmis sont des indicateurs distincts. Ils ne constituent pas une mesure de couverture de code ou de couverture fonctionnelle.

L’exhaustivité de l’ALU concerne uniquement les entrées binaires aux largeurs 1 et 4.

Les scénarios FIFO VUnit sont dirigés et utilisent une largeur de 8 bits. Ils ne couvrent pas toutes les séquences possibles ni tous les paramètres.

Extensions prévues :

- Reset de la FIFO pendant une activité.
- Séquences FIFO plus longues avec modèle de référence.
- Autres largeurs de données pour la FIFO.
- Reset du RX pendant une réception.
- Séquences UART plus longues et écarts de baudrate.
- Reset de `uart_echo` pendant une réception ou une émission.
- Vérification détaillée des octets conservés et refusés pendant une saturation.
- Extension progressive de VUnit aux autres composants.

Les simulations RTL ne reproduisent pas la métastabilité physique, les délais d’implémentation ou les conditions électriques d’une carte.

Un avertissement de valeur indéfinie peut apparaître à l’instant initial de l’ALU, avant stabilisation de la logique combinatoire. Les vérifications fonctionnelles sont effectuées après stabilisation.

## Fichiers générés

Les sources, les testbenches, les scripts et la description des dépendances sont conservés dans Git.

Les fichiers locaux générés sont exclus avec :

```gitignore
*.cf
*.vcd
*.o
.venv/
__pycache__/
vunit_out/
reports/
```

Les journaux VUnit sont disponibles localement dans `vunit_out/test_output/`.

## Prochaines étapes

- Définir un protocole UART pour transmettre une opération et ses opérandes.
- Développer et vérifier le décodeur de commandes.
- Connecter le décodeur à l’ALU et renvoyer le résultat par UART.
- Vérifier le système complet avec des commandes valides, invalides et consécutives.
- Choisir une cible FPGA et réaliser la synthèse.
- Ajouter les contraintes d’horloge et analyser le timing.
- Générer le bitstream et, si une carte est disponible, valider les échanges matériels.
