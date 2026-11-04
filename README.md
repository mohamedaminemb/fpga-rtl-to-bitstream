# FPGA RTL to Bitstream

[![VHDL Simulation](https://github.com/mohamedaminemb/fpga-rtl-to-bitstream/actions/workflows/simulation.yml/badge.svg?branch=main)](https://github.com/mohamedaminemb/fpga-rtl-to-bitstream/actions/workflows/simulation.yml)

Conception de modules numériques en VHDL et construction progressive d’un flot FPGA, de la vérification RTL à la génération du bitstream.

Le dépôt rassemble les sources RTL, des testbenches auto-vérifiants, une régression Python et des tests structurés avec VUnit.

## État actuel

- **15 modules RTL**
- **16 testbenches dans la régression GHDL**, exécutés dans 17 configurations
- **Un testbench VUnit supplémentaire** : 9 scénarios sur 2 largeurs, soit 18 tests
- **4 758 vérifications dans les tests de composants de la régression GHDL**
- **256 octets pseudo-aléatoires vérifiés en bouclage UART**

Les deux suites ont réussi localement. Le badge indique le résultat du workflow publié sur la branche `main`.

La synthèse, l’analyse de timing, la génération du bitstream et la validation sur carte restent à réaliser.

## Prérequis

- Python 3.12 : version utilisée pour le développement
- GHDL avec prise en charge de VHDL-2008
- VUnit 4.7.1
- GTKWave, facultatif, pour examiner les chronogrammes

L’environnement testé utilise Ubuntu 24.04 LTS et GHDL 4.1.0.

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
│   ├── tb_alu.vhd
│   └── vunit/
│       └── tb_alu_vunit.vhd
└── scripts/
    ├── run_tests.py
    └── run_vunit.py
```

Le bouclage utilise directement les modules UART dans son testbench. Il n’existe pas de module `rtl/uart_loopback.vhd`.

## Exécuter les tests

### Régression GHDL existante

Depuis la racine du dépôt :

```bash
.venv/bin/python scripts/run_tests.py
```

Message final attendu :

```text
All 16 testbenches passed.
```

Le script analyse les sources, élabore les testbenches et lance les simulations avec `--assert-level=error`.

- `source_overrides` définit les sources particulières du bouclage.
- `simulation_options` définit les configurations supplémentaires.
- L’ALU est exécutée sur 4 bits puis sur 1 bit.
- Le script s’arrête au premier échec.

### Tests VUnit

Lister les tests :

```bash
.venv/bin/python scripts/run_vunit.py --list
```

Exécuter les 18 tests :

```bash
.venv/bin/python scripts/run_vunit.py
```

Exécuter un seul test :

```bash
.venv/bin/python scripts/run_vunit.py "lib.tb_alu_vunit.width_4.subtraction_wrap"
```

Après activation de l’environnement, les mêmes commandes peuvent utiliser `python` :

```bash
source .venv/bin/activate
python scripts/run_vunit.py
```

L’activation doit être renouvelée dans chaque nouveau terminal.

### Codes de retour

Après une commande :

```bash
echo $?
```

Un code `0` indique une réussite. Un code non nul indique un échec.

## Intégration continue

Le workflow **VHDL Simulation** est configuré pour exécuter les deux suites :

1. Régression GHDL existante.
2. Tests VUnit de l’ALU.

Il se déclenche à chaque push, lors des événements de pull request couverts par son déclencheur et manuellement avec **Run workflow**.

Sur Ubuntu 24.04, il récupère le dépôt, installe GHDL, crée un environnement Python et installe les dépendances depuis `requirements-dev.txt`.

`VUNIT_SIMULATOR=ghdl` sélectionne explicitement GHDL pour VUnit.

Le workflow possède un accès en lecture au contenu du dépôt et une limite d’exécution de 10 minutes.

Les résultats et journaux sont disponibles dans l’onglet [Actions](https://github.com/mohamedaminemb/fpga-rtl-to-bitstream/actions/workflows/simulation.yml).

## Composants et vérification

| Module | Fonction | Configuration testée | Vérifications GHDL |
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

Le test d’intégration UART ajoute 256 octets envoyés et comparés automatiquement. Ce nombre d’octets est distinct du nombre de vérifications du tableau.

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

### FIFO synchrone

`fifo_sync` utilise une mémoire, deux pointeurs circulaires et un compteur d’occupation.

Les demandes sont acceptées selon l’occupation avant le front :

| État avant deux demandes simultanées | Écriture | Lecture |
|---|---|---|
| Vide | Acceptée | Refusée |
| Occupation intermédiaire | Acceptée | Acceptée |
| Pleine | Refusée | Acceptée |

La sortie de lecture est enregistrée et conserve sa valeur sans lecture acceptée.

Le reset vide logiquement la FIFO sans effacer le tableau mémoire.

### UART TX/RX

Le format utilisé est 8N1 : start bas, huit bits LSB d’abord, stop haut.

Le TX copie l’octet lors de l’acceptation de `start`. Les demandes présentées uniquement pendant `busy` sont ignorées. `done` est activé après la durée complète du stop.

Le RX synchronise son entrée et échantillonne près du milieu des bits. Il exige actuellement un `CLKS_PER_BIT` pair, supérieur ou égal à 4.

Un stop correct produit `valid`. Un stop incorrect produit `frame_error` sans modifier le dernier octet valide.

Un test de récupération a révélé une fausse détection de start après erreur. L’état `WAIT_IDLE` corrige ce comportement en attendant le retour au niveau haut.

### Bouclage UART

```text
Octet attendu → uart_tx → ligne série → uart_rx → Comparaison
```

Le test utilise une horloge commune et `CLKS_PER_BIT = 8` pour les deux modules.

Un LFSR de 16 bits, initialisé avec la graine fixe `0xACE1`, fournit 256 octets pseudo-aléatoires reproductibles.

Le moniteur compare les octets reçus et contrôle les événements de réception et de fin d’émission.

Les valeurs peuvent se répéter. Une marge de repos est insérée entre les trames.

## ALU et tests structurés

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

`tb/vunit/tb_alu_vunit.vhd` propose neuf scénarios nommés :

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

Ces scénarios dirigés complètent le testbench exhaustif ; ils ne le remplacent pas.

La détection d’échec a été vérifiée en modifiant temporairement un résultat attendu. Les deux configurations concernées ont échoué, puis les 18 tests ont réussi après restauration.

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

Pour `button_conditioner`, analyser d’abord ses composants `sync_2ff`, `debouncer` et `edge_detector`.

Après génération d’une trace :

```bash
gtkwave uart_loopback.vcd
```

Les testbenches VUnit sont lancés avec `run_vunit.py`, qui gère leurs bibliothèques et leur configuration.

## Configuration de l’éditeur

Le fichier `vhdl_ls.toml` configure l’association des sources aux bibliothèques pour l’analyse dans l’éditeur.

Cette configuration est indépendante des bibliothèques de compilation gérées par GHDL et VUnit.

## Limites de vérification

Les vérifications, les scénarios et les octets transmis sont des indicateurs distincts. Ils ne constituent pas une mesure de couverture de code ou de couverture fonctionnelle.

L’exhaustivité de l’ALU concerne uniquement les entrées binaires aux largeurs 1 et 4.

Extensions prévues :

- Plusieurs paramètres et cas limites des autres composants.
- FIFO de profondeur 1 et de profondeur non puissance de deux.
- Reset du RX pendant une réception.
- Trames UART consécutives et écarts de baudrate.
- Migration progressive d’autres testbenches vers VUnit.

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
```

Les journaux VUnit sont disponibles localement dans `vunit_out/test_output/`.

## Prochaines étapes

- Étendre la vérification structurée aux autres composants
- Produire et conserver des rapports de régression
- Intégrer FIFO, UART et ALU
- Développer une interface de commandes et une banque de registres
- Synthèse, contraintes et analyse de timing
- Génération du bitstream et validation sur carte FPGA