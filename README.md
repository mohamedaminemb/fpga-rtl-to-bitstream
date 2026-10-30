# FPGA RTL to Bitstream

[![VHDL Simulation](https://github.com/mohamedaminemb/fpga-rtl-to-bitstream/actions/workflows/simulation.yml/badge.svg?branch=main)](https://github.com/mohamedaminemb/fpga-rtl-to-bitstream/actions/workflows/simulation.yml)

Conception de modules numériques en VHDL et construction progressive d’un flot FPGA, de la vérification RTL à la génération du bitstream.

Le dépôt rassemble les sources RTL, leurs testbenches auto-vérifiants et une régression Python exécutée localement et automatiquement avec GitHub Actions.

## État actuel

Le projet contient des composants combinatoires et séquentiels, une chaîne de traitement de bouton et une machine à états de détection de séquence.

| Module | Description | Configuration testée | Vérifications |
|---|---|---|---:|
| `mux21` | Multiplexeur combinatoire 2 vers 1 | Entrées binaires | 8 |
| `adder_sub` | Additionneur/soustracteur non signé | `N = 8` | 4 |
| `reg_en` | Registre avec reset synchrone et enable | `WIDTH = 8` | 7 |
| `counter_en` | Compteur avec reset synchrone et enable | `WIDTH = 3` | 14 |
| `clock_enable` | Générateur d’autorisation périodique | `DIVISOR = 4` | 16 |
| `edge_detector` | Détecteur de montée d’un signal échantillonné | Entrée synchrone d’un bit | 10 |
| `sync_2ff` | Synchroniseur à deux bascules | Entrée d’un bit | 13 |
| `debouncer` | Filtre anti-rebond | `STABLE_CYCLES = 3` | 25 |
| `button_conditioner` | Intégration du traitement de bouton | `STABLE_CYCLES = 3` | 88 |
| `sequence_detector` | FSM de détection de `1011` avec chevauchement | Flux binaire synchrone | 46 |
| **Total** | **10 testbenches** | | **231** |

La régression locale des dix testbenches a réussi avec un code de retour égal à `0`. Le badge indique le résultat du workflow publié sur la branche `main`.

La synthèse, l’analyse de timing, la génération du bitstream et la validation sur carte restent à réaliser.

## Prérequis

- Python 3
- GHDL avec prise en charge de VHDL-2008
- GTKWave, facultatif, pour visualiser les chronogrammes

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
│   └── sequence_detector.vhd
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
│   └── tb_sequence_detector.vhd
└── scripts/
    └── run_tests.py
```

- `rtl/` : descriptions matérielles destinées à la synthèse.
- `tb/` : bancs de test de simulation.
- `scripts/` : automatisation de la régression.
- `.github/workflows/` : configuration de l’intégration continue.
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
All 10 testbenches passed.
```

Pour consulter le code de retour immédiatement après l’exécution :

```bash
echo $?
```

Un code `0` indique la réussite.

Le script doit être exécuté depuis la racine du dépôt. Il ne génère pas de traces VCD. L’ordre des modules respecte les dépendances : les composants sont analysés avant le module d’intégration qui les utilise.

## Intégration continue

Le workflow **VHDL Simulation** s’exécute à chaque push, lors des événements de pull request couverts par son déclencheur et à la demande avec **Run workflow**.

Sur une machine GitHub sous Ubuntu 24.04, il :

1. Récupère le dépôt.
2. Installe GHDL et Python 3.
3. Affiche leurs versions.
4. Exécute `python3 scripts/run_tests.py`.

Le workflow dispose d’un accès en lecture au contenu du dépôt et d’une limite d’exécution de 10 minutes.

Les résultats et journaux sont disponibles dans l’onglet [Actions](https://github.com/mohamedaminemb/fpga-rtl-to-bitstream/actions/workflows/simulation.yml).

La CI réalise actuellement la vérification RTL. La synthèse et la validation matérielle restent à intégrer au flot.

## Composants RTL

### Multiplexeur — `mux21`

Circuit combinatoire :

| `sel` | Sortie |
|---|---|
| `'0'` | `y = a` |
| `'1'` | `y = b` |

Les huit combinaisons binaires sont vérifiées. Une modification temporaire d’un résultat attendu a également confirmé la détection d’erreur par assertion.

### Additionneur/soustracteur — `adder_sub`

Le générique `N` définit la largeur, égale à 8 par défaut.

| `sub` | Opération |
|---|---|
| `'0'` | Addition |
| `'1'` | Soustraction |

Les calculs utilisent `unsigned` et `numeric_std`. Le résultat est limité à `N` bits, modulo `2^N`, sans sortie de retenue ni indicateur de dépassement.

Les tests sur 8 bits vérifient :

| Opération | Résultat |
|---|---:|
| `15 + 10` | 25 |
| `25 - 10` | 15 |
| `5 - 10` | 251 |
| `200 + 100` | 44 |

### Registre — `reg_en`

Au front montant :

- Si `rst = '1'`, remettre la sortie à zéro.
- Sinon, si `en = '1'`, charger l’entrée.
- Sinon, conserver la valeur.

Le générique `WIDTH` vaut 8 par défaut. Le reset est synchrone, actif à l’état haut et prioritaire.

Les sept vérifications couvrent les chargements, le maintien, le reset et sa priorité.

### Compteur — `counter_en`

Compteur non signé de `WIDTH` bits, avec reset synchrone prioritaire et enable.

Le comptage s’effectue modulo `2^WIDTH`. La valeur maximale revient à zéro uniquement lors d’une nouvelle incrémentation.

Les 14 vérifications sur 3 bits couvrent le comptage, le maintien, le débordement et le reset. Le chronogramme a été inspecté.

### Générateur de clock enable — `clock_enable`

Le module produit `tick` pendant un cycle tous les `DIVISOR` cycles. Le paramètre est strictement positif et vaut 4 par défaut.

Après reset, pour `DIVISOR = 4` :

```text
Cycle :  1 2 3 4 5 6 7 8
tick  :  0 0 0 1 0 0 0 1
```

Le reset est synchrone et remet le comptage à zéro. `tick` est une autorisation destinée à une logique cadencée par `clk`.

Les 16 vérifications couvrent la périodicité et le redémarrage après reset.

### Détecteur de front — `edge_detector`

Le module compare l’entrée synchrone à son échantillon précédent :

```text
rise_pulse suivant = NON previous ET sig_in
previous suivant   = sig_in
```

La sortie est enregistrée au front montant et reste active un cycle par montée détectée.

Le reset remet les deux mémoires à zéro. Une entrée haute au premier front hors reset produit donc une impulsion.

Les dix vérifications couvrent les montées, les descentes, le maintien et le reset. Le chronogramme a été inspecté.

### Synchroniseur — `sync_2ff`

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

Les 13 vérifications couvrent la propagation des niveaux, le maintien, l’absence de changement entre les fronts et le reset.

Ce module est destiné à un signal de niveau d’un bit suffisamment stable pour être échantillonné. Il ne garantit pas la capture d’impulsions brèves et ne constitue pas une solution générale pour un bus multibit.

La simulation RTL ne reproduit pas la métastabilité physique. Les attributs FPGA, le placement et les contraintes seront traités lors de l’implémentation.

### Anti-rebond — `debouncer`

Le module accepte une nouvelle valeur après `STABLE_CYCLES` observations consécutives différentes de la sortie actuelle. L’entrée doit être déjà synchronisée.

- Entrée égale à la sortie : annuler l’attente.
- Entrée différente : compter les observations.
- À la dernière observation requise : accepter l’entrée.
- Reset : remettre sortie et compteur à zéro.

Pour `STABLE_CYCLES = 3` :

```text
Entrée :  1 0 1 1 1 0 1
Sortie :  0 0 0 0 1 1 1
```

Les 25 vérifications couvrent les impulsions courtes, les rebonds en montée et descente, et le reset pendant l’attente. Le chronogramme a été inspecté.

## Intégration du bouton — `button_conditioner`

Le module assemble les composants suivants :

```text
button_in → sync_2ff → debouncer → edge_detector → press_pulse
                          │
                          └──────────────────────→ button_clean
```

Les composants partagent la même horloge et le même reset synchrone. Le paramètre `STABLE_CYCLES` est transmis à l’anti-rebond.

- `button_in` : entrée extérieure active à l’état haut.
- `button_clean` : état synchronisé et filtré.
- `press_pulse` : impulsion d’un cycle à chaque montée filtrée.

Le détecteur observe la montée de `button_clean` au front suivant : l’impulsion est décalée d’un cycle.

Avec `STABLE_CYCLES = 3`, pour une entrée appliquée au front descendant :

```text
Front        : 1 2 3 4 5 6 7
button_clean : 0 0 0 0 1 1 1
press_pulse  : 0 0 0 0 0 1 0
```

Les 88 vérifications couvrent le reset initial, deux appuis propres, le maintien prolongé, le relâchement et les rebonds simulés.

Les rebonds utilisés sont des stimuli numériques simplifiés. Une entrée maintenue haute après reset est interprétée comme un appui une fois synchronisée et filtrée.

## Machine à états — `sequence_detector`

Le module reçoit un bit synchrone à chaque front montant et détecte la séquence `1011`, avec chevauchement.

| État | Préfixe reconnu |
|---|---|
| `S0` | Aucun préfixe utile |
| `S1` | `1` |
| `S10` | `10` |
| `S101` | `101` |

### Transitions

| État actuel | Bit reçu | État suivant | `detected` suivant |
|---|---|---|---|
| `S0` | 0 | `S0` | 0 |
| `S0` | 1 | `S1` | 0 |
| `S1` | 0 | `S10` | 0 |
| `S1` | 1 | `S1` | 0 |
| `S10` | 0 | `S0` | 0 |
| `S10` | 1 | `S101` | 0 |
| `S101` | 0 | `S10` | 0 |
| `S101` | 1 | `S1` | 1 |

La détection est enregistrée au front montant qui reçoit le dernier bit de la séquence.

Après détection, le retour à `S1` conserve le dernier `1` comme début potentiel d’une nouvelle séquence :

```text
Entrée    : 1 0 1 1 0 1 1
Détection : 0 0 0 1 0 0 1
```

Le reset est synchrone, actif à l’état haut. Il remet l’état à `S0` et la sortie à zéro.

### Vérification

Le testbench utilise des procédures pour appliquer les flux, vérifier les résultats et réinitialiser la FSM. Le nombre de vérifications est calculé automatiquement.

Les 46 vérifications couvrent :

- Une suite de zéros sans détection.
- Une détection simple et la disparition de l’impulsion.
- Deux détections avec chevauchement.
- La conservation d’un suffixe utile après une reconnaissance partielle.
- Un préfixe incorrect et des uns successifs.
- Un reset après réception de `101`.
- Une nouvelle séquence complète après ce reset.

Le reset interne est vérifié par le comportement observable : après interruption de `101`, un nouveau `1` ne doit pas compléter l’ancienne séquence.

Le chronogramme a confirmé le retour à `S0` au reset et l’absence de détection prématurée après redémarrage.

## Simulations individuelles

Exécuter les commandes depuis la racine du dépôt.

### Composants indépendants

Pour analyser les composants et leurs testbenches :

```bash
ghdl -a --std=08 rtl/mux21.vhd tb/tb_mux21.vhd
ghdl -a --std=08 rtl/adder_sub.vhd tb/tb_adder_sub.vhd
ghdl -a --std=08 rtl/reg_en.vhd tb/tb_reg_en.vhd
ghdl -a --std=08 rtl/counter_en.vhd tb/tb_counter_en.vhd
ghdl -a --std=08 rtl/clock_enable.vhd tb/tb_clock_enable.vhd
ghdl -a --std=08 rtl/edge_detector.vhd tb/tb_edge_detector.vhd
ghdl -a --std=08 rtl/sync_2ff.vhd tb/tb_sync_2ff.vhd
ghdl -a --std=08 rtl/debouncer.vhd tb/tb_debouncer.vhd
ghdl -a --std=08 rtl/sequence_detector.vhd tb/tb_sequence_detector.vhd
```

Élaborer et exécuter ensuite le testbench choisi. Exemple pour la FSM :

```bash
ghdl -e --std=08 tb_sequence_detector
ghdl -r --std=08 tb_sequence_detector --assert-level=error --vcd=sequence_detector.vcd
```

### Intégration du bouton

Analyser les dépendances avant le module d’intégration :

```bash
ghdl -a --std=08 rtl/sync_2ff.vhd rtl/debouncer.vhd rtl/edge_detector.vhd rtl/button_conditioner.vhd tb/tb_button_conditioner.vhd
ghdl -e --std=08 tb_button_conditioner
ghdl -r --std=08 tb_button_conditioner --assert-level=error --vcd=button_conditioner.vcd
```

### Résultats attendus

| Testbench | Vérifications | Dernière vérification ou fin de simulation |
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

### Visualisation

Après génération du fichier VCD :

```bash
gtkwave sequence_detector.vcd
```

Pour la FSM, afficher `clk_tb`, `rst_tb`, `bit_in_tb`, `detected_tb` et le signal interne `state_reg`.

## Configuration de l’éditeur

Le fichier `vhdl_ls.toml` associe les sources et les testbenches à une bibliothèque commune :

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

Les 231 vérifications sont des comparaisons exécutées dans des scénarios dirigés. Elles ne constituent pas une mesure de couverture de code ou de couverture fonctionnelle.

Les extensions de vérification prévues comprennent :

- Plusieurs largeurs pour les modules paramétrables.
- Les cas `DIVISOR = 1` et `STABLE_CYCLES = 1`.
- Le reset de l’anti-rebond avec sortie haute.
- Le reset pendant un appui dans le module d’intégration.
- Des flux supplémentaires et un modèle de référence pour la FSM.

Les tests utilisent principalement des valeurs binaires. La métastabilité physique, les délais matériels et la fiabilité sur carte ne sont pas évalués par ces simulations RTL.

L’arrêt au premier échec du script Python a été contrôlé par injection temporaire d’un résultat attendu incorrect dans le testbench du multiplexeur.

## Fichiers générés

Les fichiers de travail GHDL et les traces sont générés localement et exclus du dépôt par `.gitignore`, notamment :

```gitignore
*.cf
*.vcd
*.o
```

Le dépôt conserve les sources, les testbenches, les scripts et la documentation nécessaires pour reproduire les simulations.

## Prochaines étapes

- Étendre les tests aux cas limites et à plusieurs paramètres
- Approfondir les machines à états avec un contrôleur temporisé
- FIFO synchrone et UART
- Vérification structurée avec VUnit ou cocotb
- Intégration d’un système pilotable par UART
- Synthèse, contraintes et analyse de timing
- Génération du bitstream et validation sur carte FPGA