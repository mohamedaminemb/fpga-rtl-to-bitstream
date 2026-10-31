# FPGA RTL to Bitstream

[![VHDL Simulation](https://github.com/mohamedaminemb/fpga-rtl-to-bitstream/actions/workflows/simulation.yml/badge.svg?branch=main)](https://github.com/mohamedaminemb/fpga-rtl-to-bitstream/actions/workflows/simulation.yml)

Conception de modules numériques en VHDL et construction progressive d’un flot FPGA, de la vérification RTL à la génération du bitstream.

Le dépôt rassemble les sources RTL, leurs testbenches auto-vérifiants et une régression Python exécutée localement et automatiquement avec GitHub Actions.

## État actuel

| Module | Fonction | Configuration testée | Vérifications |
|---|---|---|---:|
| `mux21` | Multiplexeur combinatoire 2 vers 1 | Entrées binaires | 8 |
| `adder_sub` | Additionneur/soustracteur non signé | `N = 8` | 4 |
| `reg_en` | Registre avec reset et enable | `WIDTH = 8` | 7 |
| `counter_en` | Compteur avec reset et enable | `WIDTH = 3` | 14 |
| `clock_enable` | Autorisation périodique | `DIVISOR = 4` | 16 |
| `edge_detector` | Détecteur de montée échantillonnée | Entrée synchrone d’un bit | 10 |
| `sync_2ff` | Synchroniseur à deux bascules | Entrée d’un bit | 13 |
| `debouncer` | Filtre anti-rebond | `STABLE_CYCLES = 3` | 25 |
| `button_conditioner` | Traitement complet de bouton | `STABLE_CYCLES = 3` | 88 |
| `sequence_detector` | Détection de `1011` avec chevauchement | Flux binaire synchrone | 46 |
| `traffic_light_controller` | FSM de feu tricolore temporisé | Durées `(3,4,2)` et `(1,1,1)` | 68 |
| `fifo_sync` | FIFO synchrone à lecture enregistrée | `WIDTH = 8`, `DEPTH = 4` | 93 |
| `uart_tx` | Émetteur UART 8N1 | `CLKS_PER_BIT = 4` | 180 |
| **Total** | **13 testbenches** | | **572** |

La régression locale des treize testbenches a réussi avec un code de retour égal à `0`. Le badge indique le résultat du workflow publié sur la branche `main`.

La réception UART, la synthèse, l’analyse de timing, la génération du bitstream et la validation sur carte restent à réaliser.

## Prérequis

- Python 3
- GHDL avec prise en charge de VHDL-2008
- GTKWave, facultatif, pour examiner les chronogrammes

Le script utilise uniquement la bibliothèque standard Python.

Environnement de développement : Ubuntu 24.04 LTS, VS Code avec TerosHDL, Git et GitHub.

```bash
python3 --version
ghdl --version
gtkwave --version
```

## Organisation du dépôt

```text
fpga-rtl-to-bitstream/
├── .github/
│   └── workflows/
│       └── simulation.yml
├── .gitignore
├── README.md
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
│   └── uart_tx.vhd
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
│   └── tb_uart_tx.vhd
└── scripts/
    └── run_tests.py
```

- `rtl/` : descriptions matérielles destinées à la synthèse.
- `tb/` : bancs de test de simulation.
- `scripts/` : automatisation de la régression.
- `.github/workflows/` : intégration continue.
- `vhdl_ls.toml` : configuration de l’analyseur VHDL de l’éditeur.

Les dossiers de contraintes et de documentation seront complétés au fil du développement.

## Lancer la régression

Depuis la racine du dépôt :

```bash
python3 scripts/run_tests.py
```

Pour chaque module, le script analyse les sources, élabore le testbench et lance la simulation avec `--assert-level=error`.

Il s’arrête dès qu’une commande échoue et transmet son code de retour.

Message final attendu :

```text
All 13 testbenches passed.
```

Pour consulter le code de retour immédiatement après l’exécution :

```bash
echo $?
```

Un code `0` indique la réussite.

Le script doit être exécuté depuis la racine du dépôt. Il ne génère pas de traces VCD. Les composants sont analysés avant les modules d’intégration qui les utilisent.

## Intégration continue

Le workflow **VHDL Simulation** s’exécute à chaque push, lors des événements de pull request couverts par son déclencheur et à la demande avec **Run workflow**.

Sur une machine GitHub sous Ubuntu 24.04, il :

1. Récupère le dépôt.
2. Installe GHDL et Python 3.
3. Affiche leurs versions.
4. Exécute la régression Python.

Le workflow possède un accès en lecture au contenu du dépôt et une limite d’exécution de 10 minutes.

Les journaux sont disponibles dans l’onglet [Actions](https://github.com/mohamedaminemb/fpga-rtl-to-bitstream/actions/workflows/simulation.yml).

La CI réalise actuellement la vérification RTL. La synthèse et la validation matérielle restent à intégrer au flot.

## Composants de base

### `mux21`

Multiplexeur combinatoire : `y = a` lorsque `sel = '0'`, sinon `y = b`.

Les huit combinaisons binaires sont vérifiées. Une modification temporaire d’un résultat attendu a également confirmé la détection d’erreur par assertion.

### `adder_sub`

Additionneur/soustracteur non signé de `N` bits :

- `sub = '0'` : addition.
- `sub = '1'` : soustraction.

Les calculs utilisent `unsigned` et `numeric_std`. Le résultat est conservé sur `N` bits, modulo `2^N`, sans sortie de retenue ni indicateur de dépassement.

Les tests sur 8 bits vérifient :

| Opération | Résultat |
|---|---:|
| `15 + 10` | 25 |
| `25 - 10` | 15 |
| `5 - 10` | 251 |
| `200 + 100` | 44 |

### `reg_en`

Registre de `WIDTH` bits avec reset synchrone actif à l’état haut, prioritaire sur l’enable.

Au front montant, il charge l’entrée si `en = '1'`, sinon conserve sa valeur.

Les tests couvrent les chargements, le maintien et le comportement du reset.

### `counter_en`

Compteur non signé de `WIDTH` bits, avec reset synchrone prioritaire et enable.

Le comptage s’effectue modulo `2^WIDTH`. La valeur maximale revient à zéro lors d’une nouvelle incrémentation.

Les tests couvrent le comptage, le maintien, le débordement et le reset.

### `clock_enable`

Produit une autorisation `tick` pendant un cycle tous les `DIVISOR` cycles.

Pour `DIVISOR = 4`, après reset :

```text
Cycle :  1 2 3 4 5 6 7 8
tick  :  0 0 0 1 0 0 0 1
```

Le reset synchrone recommence le comptage à zéro. `tick` est destiné à être utilisé comme enable dans une logique cadencée par `clk`.

### `edge_detector`

Détecte une montée entre deux échantillons successifs d’une entrée synchrone :

```text
rise_pulse suivant = NON previous ET sig_in
previous suivant   = sig_in
```

La sortie est enregistrée. Le reset remet les deux mémoires à zéro.

Une entrée haute au premier front hors reset produit une impulsion. Une transition complète entre deux observations peut ne pas être détectée.

### `sync_2ff`

Deux bascules successives échantillonnent une entrée d’un bit :

```text
async_in → stage1 → sync_out
```

Au front montant :

```text
stage1 suivant   = async_in
sync_out suivant = ancien stage1
```

Le reset synchrone remet les deux bascules à zéro.

Le module ne garantit pas la capture d’impulsions brèves et ne constitue pas une solution générale pour un bus multibit.

La simulation RTL ne reproduit pas la métastabilité physique. Les attributs FPGA, le placement et les contraintes seront traités lors de l’implémentation.

### `debouncer`

Accepte une nouvelle valeur après `STABLE_CYCLES` observations consécutives différentes de la sortie actuelle. L’entrée doit être déjà synchronisée.

- Entrée égale à la sortie : annuler l’attente.
- Entrée différente : compter les observations.
- Dernière observation requise : accepter l’entrée.
- Reset : remettre sortie et compteur à zéro.

Pour trois observations :

```text
Entrée :  1 0 1 1 1 0 1
Sortie :  0 0 0 0 1 1 1
```

Les tests couvrent les changements courts, les rebonds en montée et descente, et le reset pendant l’attente.

## Traitement du bouton — `button_conditioner`

```text
button_in → sync_2ff → debouncer → edge_detector → press_pulse
                          │
                          └──────────────────────→ button_clean
```

Les composants partagent la même horloge et le même reset synchrone. Le paramètre `STABLE_CYCLES` est transmis à l’anti-rebond.

Le détecteur observe la montée filtrée au front suivant. Pour `STABLE_CYCLES = 3`, dans le scénario d’une entrée appliquée au front descendant :

```text
Front        : 1 2 3 4 5 6 7
button_clean : 0 0 0 0 1 1 1
press_pulse  : 0 0 0 0 0 1 0
```

Les tests couvrent les appuis propres, le maintien, le relâchement et les rebonds simulés.

Une entrée maintenue haute après reset est interprétée comme un appui une fois synchronisée et filtrée.

## Détecteur de séquence — `sequence_detector`

FSM recevant un bit synchrone à chaque front montant et détectant `1011`, avec chevauchement.

| État actuel | Bit reçu | État suivant | Détection |
|---|---|---|---|
| `S0` | 0 | `S0` | 0 |
| `S0` | 1 | `S1` | 0 |
| `S1` | 0 | `S10` | 0 |
| `S1` | 1 | `S1` | 0 |
| `S10` | 0 | `S0` | 0 |
| `S10` | 1 | `S101` | 0 |
| `S101` | 0 | `S10` | 0 |
| `S101` | 1 | `S1` | 1 |

La détection est enregistrée au front recevant le dernier bit du motif. Le retour à `S1` conserve le dernier `1` pour une éventuelle détection chevauchante.

```text
Entrée    : 1 0 1 1 0 1 1
Détection : 0 0 0 1 0 0 1
```

Les tests couvrent les détections, les séquences incorrectes, les suffixes utiles et un reset pendant une reconnaissance partielle.

## Contrôleur temporisé — `traffic_light_controller`

FSM de Moore commandant la rotation :

```text
S_RED → S_GREEN → S_YELLOW → S_RED
```

| État | Rouge | Vert | Orange | Durée par défaut |
|---|---|---|---|---:|
| `S_RED` | 1 | 0 | 0 | 3 cycles |
| `S_GREEN` | 0 | 1 | 0 | 4 cycles |
| `S_YELLOW` | 0 | 0 | 1 | 2 cycles |

Un compteur partagé mesure la durée de chaque état et revient à zéro à chaque transition.

Le reset synchrone impose le rouge et remet le compteur à zéro.

Les configurations `(3,4,2)` et `(1,1,1)` sont testées en parallèle. Les vérifications couvrent les durées, les rotations, les sorties et le reset en fonctionnement.

Les durées sont exprimées en cycles pour la simulation.

## FIFO synchrone — `fifo_sync`

File respectant l’ordre First In, First Out.

| Élément | Rôle |
|---|---|
| `WIDTH` | Nombre de bits par donnée |
| `DEPTH` | Capacité en nombre de données |
| `wr_en`, `rd_en` | Demandes d’écriture et de lecture |
| `data_in` | Donnée à écrire |
| `data_out` | Dernière donnée lue, sortie enregistrée |
| `full`, `empty` | Indicateurs d’occupation |

Les demandes sont acceptées selon l’occupation avant le front montant.

| État avant deux demandes simultanées | Écriture | Lecture |
|---|---|---|
| Vide | Acceptée | Refusée |
| Occupation intermédiaire | Acceptée | Acceptée |
| Pleine | Refusée | Acceptée |

Sans lecture acceptée, `data_out` conserve sa valeur.

Le reset synchrone est prioritaire. Il remet les pointeurs, l’occupation et la sortie à zéro sans effacer le tableau mémoire.

Les 93 vérifications couvrent l’ordre des données, les limites pleine/vide, les pointeurs circulaires, les opérations simultanées et le reset d’une FIFO pleine avec demandes actives.

## Émetteur UART — `uart_tx`

Émetteur série au format **8N1** :

```text
Repos | Start | b0 b1 b2 b3 b4 b5 b6 b7 | Stop
  1   |   0   |    Données, LSB d'abord   |  1
```

### Interface

| Élément | Rôle |
|---|---|
| `CLKS_PER_BIT` | Nombre de cycles d’horloge par bit |
| `clk` | Horloge |
| `rst` | Reset synchrone actif à l’état haut |
| `start` | Demande d’envoi |
| `data_in` | Octet à transmettre |
| `tx` | Ligne série enregistrée |
| `busy` | Transmission en cours |
| `done` | Impulsion d’un cycle après la fin du stop |

La FSM comporte quatre états : `IDLE`, `START_BIT`, `DATA_BITS` et `STOP_BIT`.

### Contrat de transmission

Une demande est acceptée uniquement dans `IDLE`. L’octet est alors copié dans un registre interne.

Chaque bit dure `CLKS_PER_BIT` périodes d’horloge. `busy` reste actif pendant le start, les données et le stop.

À la fin de la durée complète du stop, `busy` est désactivé et `done` est activé pendant un cycle.

Les demandes présentées uniquement pendant la transmission sont ignorées. Si `start` reste haut jusqu’au retour dans `IDLE`, il peut déclencher un nouvel envoi.

Le reset interrompt la transmission et remet `tx = '1'`, `busy = '0'` et `done = '0'`.

### Temporisation

```text
Durée d’un bit = CLKS_PER_BIT × période de clk
Durée d’une trame 8N1 = 10 × durée d’un bit
Baudrate = fréquence de clk / CLKS_PER_BIT
```

Avec une période de 10 ns et `CLKS_PER_BIT = 4`, un bit dure 40 ns et une trame dure 400 ns.

Ce réglage sert à accélérer les simulations. Le choix d’un baudrate réel et son erreur d’arrondi seront traités lors de l’intégration.

### Vérification

Les 180 vérifications contrôlent :

- Le reset initial.
- Une trame complète de `0xA6`, cycle par cycle.
- L’ordre des bits et leur durée.
- `busy` et `done`.
- La conservation de l’octet malgré un changement de `data_in`.
- Une demande ignorée pendant `busy`.
- L’absence de transmission différée pour cette demande.
- Une transmission de `0x00` interrompue pendant les données.
- Le reset synchrone et sa priorité sur `start`.
- Le maintien du reset et l’absence de reprise automatique.

Le chronogramme a été inspecté. Les autres octets, les autres valeurs de `CLKS_PER_BIT`, le reset pendant le start ou le stop et une nouvelle transmission après reset restent à tester.

## Simulations individuelles

Exécuter les commandes depuis la racine du dépôt.

Exemple pour l’UART TX :

```bash
ghdl -a --std=08 rtl/uart_tx.vhd tb/tb_uart_tx.vhd
ghdl -e --std=08 tb_uart_tx
ghdl -r --std=08 tb_uart_tx --assert-level=error --vcd=uart_tx.vcd
```

Pour un autre composant indépendant, remplacer les noms du module et du testbench.

Pour l’intégration du bouton, analyser d’abord les dépendances :

```bash
ghdl -a --std=08 rtl/sync_2ff.vhd rtl/debouncer.vhd rtl/edge_detector.vhd rtl/button_conditioner.vhd tb/tb_button_conditioner.vhd
ghdl -e --std=08 tb_button_conditioner
ghdl -r --std=08 tb_button_conditioner --assert-level=error --vcd=button_conditioner.vcd
```

### Résultats attendus

| Testbench | Vérifications | Dernière vérification ou fin |
|---|---:|---|
| `tb_mux21` | 8 | 80 ns |
| `tb_adder_sub` | 4 | 40 ns |
| `tb_reg_en` | 7 | 46 ns |
| `tb_counter_en` | 14 | 126 ns |
| `tb_clock_enable` | 16 | 156 ns |
| `tb_edge_detector` | 10 | 86 ns |
| `tb_sync_2ff` | 13 | 106 ns |
| `tb_debouncer` | 25 | 246 ns |
| `tb_button_conditioner` | 88 | 436 ns |
| `tb_sequence_detector` | 46 | 466 ns |
| `tb_traffic_light_controller` | 68 | 326 ns |
| `tb_fifo_sync` | 93 | 296 ns |
| `tb_uart_tx` | 180 | 586 ns |

Après génération d’une trace :

```bash
gtkwave uart_tx.vcd
```

## Configuration de l’éditeur

Le fichier `vhdl_ls.toml` associe les sources et testbenches à une bibliothèque commune :

```toml
standard = "2008"

[libraries]
defaultlib.files = [
    "rtl/*.vhd",
    "tb/*.vhd",
]
```

Cette configuration est indépendante de la compilation GHDL du script Python.

## Limites de vérification

Les 572 vérifications sont des comparaisons exécutées dans des scénarios dirigés. Elles ne constituent pas une mesure de couverture de code ou de couverture fonctionnelle.

Les extensions prévues comprennent plusieurs paramètres, des cas limites, des modèles de référence et des scénarios aléatoires.

Les tests utilisent principalement des valeurs binaires. La métastabilité physique, les délais matériels et la fiabilité sur carte ne sont pas évalués par ces simulations RTL.

L’arrêt au premier échec de la régression a été contrôlé par injection temporaire d’un résultat attendu incorrect dans le testbench du multiplexeur.

## Fichiers générés

Les fichiers de travail GHDL et les traces sont produits localement et exclus du dépôt par `.gitignore`, notamment :

```gitignore
*.cf
*.vcd
*.o
```

Le dépôt conserve les sources, les testbenches, les scripts et la documentation nécessaires pour reproduire les simulations.

## Prochaines étapes

- UART RX
- Bouclage TX vers RX et vérification des octets reçus
- Extension des tests aux cas limites et à plusieurs paramètres
- Vérification structurée avec VUnit ou cocotb
- Intégration FIFO et UART
- Système pilotable par commandes UART
- Synthèse, contraintes et analyse de timing
- Génération du bitstream et validation sur carte FPGA