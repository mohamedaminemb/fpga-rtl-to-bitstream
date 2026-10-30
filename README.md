# FPGA RTL to Bitstream

[![VHDL Simulation](https://github.com/mohamedaminemb/fpga-rtl-to-bitstream/actions/workflows/simulation.yml/badge.svg?branch=main)](https://github.com/mohamedaminemb/fpga-rtl-to-bitstream/actions/workflows/simulation.yml)

Conception de modules numériques en VHDL et construction progressive d’un flot FPGA, de la vérification RTL à la génération du bitstream.

Le dépôt rassemble les sources RTL, leurs testbenches auto-vérifiants et une régression Python exécutée localement et automatiquement avec GitHub Actions.

## État actuel

Sept modules RTL sont implémentés et vérifiés en simulation.

| Module | Description | Configuration testée | Vérifications |
|---|---|---|---:|
| `mux21` | Multiplexeur combinatoire 2 vers 1 | Entrées binaires | 8 |
| `adder_sub` | Additionneur/soustracteur non signé | `N = 8` | 4 |
| `reg_en` | Registre avec reset synchrone et enable | `WIDTH = 8` | 7 |
| `counter_en` | Compteur avec reset synchrone et enable | `WIDTH = 3` | 14 |
| `clock_enable` | Générateur d’autorisation périodique | `DIVISOR = 4` | 16 |
| `edge_detector` | Détecteur de montée d’un signal échantillonné | Entrée synchrone d’un bit | 10 |
| `sync_2ff` | Synchroniseur à deux bascules | Entrée d’un bit | 13 |
| **Total** | **7 testbenches** | | **72** |

Les simulations individuelles ont réussi. Le script de régression inclut les sept testbenches. Le badge indique le résultat du workflow publié sur la branche `main`.

La synthèse, l’analyse de timing, la génération du bitstream et la validation sur carte restent à réaliser.

## Prérequis

- Python 3
- GHDL avec prise en charge de VHDL-2008
- GTKWave, facultatif, pour visualiser les chronogrammes

Le script utilise uniquement la bibliothèque standard Python.

Environnement de développement : Ubuntu 24.04 LTS, VS Code avec TerosHDL, Git et GitHub.

Pour consulter les versions installées :

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
│   └── sync_2ff.vhd
├── tb/
│   ├── tb_mux21.vhd
│   ├── tb_adder_sub.vhd
│   ├── tb_reg_en.vhd
│   ├── tb_counter_en.vhd
│   ├── tb_clock_enable.vhd
│   ├── tb_edge_detector.vhd
│   └── tb_sync_2ff.vhd
└── scripts/
    └── run_tests.py
```

- `rtl/` : descriptions matérielles destinées à la synthèse.
- `tb/` : bancs de test de simulation.
- `scripts/` : automatisation de la régression.
- `.github/workflows/` : configuration de l’intégration continue.
- `vhdl_ls.toml` : configuration de l’analyseur VHDL de l’éditeur.

Les dossiers de contraintes et de documentation seront complétés au fil du développement.

## Lancer tous les tests

Depuis la racine du dépôt :

```bash
python3 scripts/run_tests.py
```

Pour chaque module, le script :

1. Analyse le fichier RTL et son testbench.
2. Élabore le testbench.
3. Exécute la simulation avec `--assert-level=error`.
4. Affiche `PASS` après réussite des commandes.

Il s’arrête dès qu’une commande échoue et transmet son code de retour.

Résultat attendu après réussite des sept testbenches :

```text
All 7 testbenches passed.
```

Pour consulter le code de retour immédiatement après l’exécution :

```bash
echo $?
```

- `0` : régression réussie.
- Autre valeur : échec.

Le script doit être exécuté depuis la racine du dépôt. Il ne génère pas de traces VCD.

## Intégration continue

Le workflow **VHDL Simulation**, défini dans `.github/workflows/simulation.yml`, s’exécute :

- À chaque push.
- Lors des événements de pull request couverts par le déclencheur.
- À la demande avec le bouton **Run workflow**.

Il utilise une machine GitHub sous Ubuntu 24.04 et réalise les étapes suivantes :

1. Récupération du dépôt.
2. Installation de GHDL et Python 3.
3. Affichage des versions des outils.
4. Exécution de `python3 scripts/run_tests.py`.

Le workflow possède un accès en lecture au contenu du dépôt et une limite d’exécution de 10 minutes.

Une erreur de compilation, d’élaboration ou de simulation fait échouer le travail. Les résultats et journaux sont disponibles dans l’onglet [Actions](https://github.com/mohamedaminemb/fpga-rtl-to-bitstream/actions/workflows/simulation.yml).

La CI exécute les tests RTL. La synthèse et la validation matérielle seront ajoutées dans les phases suivantes du projet.

## Modules RTL

### Multiplexeur — `mux21`

Circuit combinatoire sélectionnant une entrée selon `sel` :

| `sel` | Sortie |
|---|---|
| `'0'` | `y = a` |
| `'1'` | `y = b` |

Le testbench vérifie les huit combinaisons binaires de `a`, `b` et `sel`.

La détection d’erreur a été contrôlée en modifiant temporairement un résultat attendu : une assertion a interrompu la simulation. La valeur correcte a ensuite été rétablie.

### Additionneur/soustracteur — `adder_sub`

Le module effectue une opération sur deux entrées de `N` bits :

| `sub` | Opération |
|---|---|
| `'0'` | `sum = a + b` |
| `'1'` | `sum = a - b` |

Le générique `N` vaut 8 par défaut.

Les calculs utilisent `unsigned` et le paquet IEEE `numeric_std`. Le résultat est limité à `N` bits : les opérations sont réalisées modulo `2^N`, sans sortie de retenue ni indicateur de dépassement.

Quatre cas sont vérifiés sur 8 bits :

| Opération | Résultat |
|---|---:|
| `15 + 10` | 25 |
| `25 - 10` | 15 |
| `5 - 10` | 251 |
| `200 + 100` | 44 |

### Registre synchrone — `reg_en`

Le registre mémorise une donnée de `WIDTH` bits au front montant de l’horloge. La largeur par défaut est de 8 bits.

| Condition au front montant | Action |
|---|---|
| `rst = '1'` | Remettre `q` à zéro |
| `rst = '0'`, `en = '1'` | Charger `d` dans `q` |
| `rst = '0'`, `en = '0'` | Conserver la valeur |

Le reset est synchrone, actif à l’état haut et prioritaire sur l’enable.

Les sept vérifications portent sur le reset initial, deux chargements, le maintien entre les fronts, le maintien avec enable inactif, le caractère synchrone du reset et sa priorité.

### Compteur synchrone — `counter_en`

Le compteur mémorise une valeur non signée sur `WIDTH` bits. La largeur par défaut est de 8 bits.

| Condition au front montant | Action |
|---|---|
| `rst = '1'` | Remettre le compteur à zéro |
| `rst = '0'`, `en = '1'` | Incrémenter le compteur |
| `rst = '0'`, `en = '0'` | Conserver la valeur |

Le reset est synchrone, actif à l’état haut et prioritaire sur l’enable.

Le comptage s’effectue modulo `2^WIDTH`. Une incrémentation après la valeur maximale ramène le compteur à zéro.

Les 14 vérifications couvrent le reset initial, l’incrémentation, le maintien pendant deux cycles, le comptage jusqu’à 7, le débordement, la reprise du comptage et le comportement du reset.

Le chronogramme a également été inspecté.

### Générateur de clock enable — `clock_enable`

Le module produit une autorisation `tick` pendant un cycle, tous les `DIVISOR` cycles d’horloge.

Le générique `DIVISOR` est strictement positif et vaut 4 par défaut. Le compteur interne évolue de `0` à `DIVISOR - 1`.

| Condition au front montant | Compteur suivant | `tick` suivant |
|---|---|---|
| `rst = '1'` | 0 | `'0'` |
| Hors reset, compteur au seuil | 0 | `'1'` |
| Hors reset, compteur sous le seuil | Compteur + 1 | `'0'` |

Le reset est synchrone et actif à l’état haut. Après sa désactivation, la première impulsion apparaît au `DIVISOR`-ième front montant.

`tick` est destiné à être utilisé comme enable dans une logique cadencée par `clk`.

Pour `DIVISOR = 4` :

```text
Cycle :  1 2 3 4 5 6 7 8
tick  :  0 0 0 1 0 0 0 1
```

Pour `DIVISOR = 1`, `tick` reste actif à chaque cycle hors reset. Ce cas limite n’est pas encore testé.

Les 16 vérifications portent sur le reset initial, la périodicité des impulsions et le redémarrage d’une période complète après un reset intermédiaire.

### Détecteur de front montant — `edge_detector`

Le module détecte un passage de `'0'` à `'1'` entre deux échantillons successifs de `sig_in`.

L’entrée est observée au front montant de `clk`. Le signal interne `previous` mémorise l’échantillon précédent. La sortie `rise_pulse` est enregistrée au même front.

Hors reset :

```text
rise_pulse suivant = NON previous ET sig_in
previous suivant   = sig_in
```

| Échantillon précédent | Entrée actuelle | Impulsion suivante |
|---|---|---|
| `'0'` | `'0'` | `'0'` |
| `'0'` | `'1'` | `'1'` |
| `'1'` | `'0'` | `'0'` |
| `'1'` | `'1'` | `'0'` |

Le reset est synchrone et actif à l’état haut. Il remet `previous` et `rise_pulse` à zéro.

Si l’entrée est déjà haute au premier front hors reset, une impulsion est produite puisque l’échantillon précédent a été remis à zéro.

Les dix vérifications couvrent le reset initial, une entrée inactive, deux montées, une descente, la durée de l’impulsion, le caractère synchrone du reset et le redémarrage avec une entrée haute.

La simulation et l’inspection du chronogramme ont confirmé ces comportements.

L’entrée doit être synchrone avec `clk`. Une transition complète entre deux observations peut ne pas être détectée.

### Synchroniseur à deux bascules — `sync_2ff`

Le module échantillonne une entrée d’un bit à travers deux bascules cadencées par la même horloge.

```text
async_in → première bascule stage1 → seconde bascule sync_out
```

Au front montant, hors reset :

```text
stage1 suivant   = async_in
sync_out suivant = ancienne valeur de stage1
```

Une valeur capturée par la première bascule atteint donc la sortie au front montant suivant.

Le reset est synchrone, actif à l’état haut et prioritaire. Il remet les deux bascules à zéro.

Les 13 vérifications portent sur :

- Le reset initial.
- L’absence de changement de sortie entre les fronts lors d’une montée et d’une descente.
- La propagation d’une montée à travers les deux bascules.
- Le maintien d’un niveau haut.
- La propagation d’une descente.
- La préparation d’une sortie haute avant reset.
- Le caractère synchrone du reset.
- La remise à zéro de la sortie.
- Le redémarrage sur deux fronts après désactivation du reset.

La simulation individuelle réussit et se termine à `106 ns`.

Le synchroniseur est destiné à un signal de niveau d’un bit qui reste stable suffisamment longtemps pour être échantillonné. Il ne garantit pas la capture d’une impulsion brève et ne constitue pas une solution générale pour un bus multibit.

La simulation RTL vérifie le comportement logique. Elle ne reproduit pas la métastabilité physique et ne prouve pas la fiabilité de la traversée asynchrone. Les attributs propres au FPGA, le placement et les contraintes seront traités lors de l’implémentation.

## Simulations individuelles

Exécuter les commandes depuis la racine du dépôt.

### Multiplexeur

```bash
ghdl -a --std=08 rtl/mux21.vhd tb/tb_mux21.vhd
ghdl -e --std=08 tb_mux21
ghdl -r --std=08 tb_mux21 --assert-level=error --vcd=mux21.vcd
```

Message attendu : `MUX: all 8 binary cases passed.`

Fin de simulation : `80 ns`.

### Additionneur/soustracteur

```bash
ghdl -a --std=08 rtl/adder_sub.vhd tb/tb_adder_sub.vhd
ghdl -e --std=08 tb_adder_sub
ghdl -r --std=08 tb_adder_sub --assert-level=error --vcd=adder_sub.vcd
```

Message attendu : `All tests passed.`

Dernière vérification : `40 ns`.

### Registre synchrone

```bash
ghdl -a --std=08 rtl/reg_en.vhd tb/tb_reg_en.vhd
ghdl -e --std=08 tb_reg_en
ghdl -r --std=08 tb_reg_en --assert-level=error --vcd=reg_en.vcd
```

Message attendu : `REG_EN: all 7 checks passed.`

Fin de simulation : `46 ns`.

### Compteur synchrone

```bash
ghdl -a --std=08 rtl/counter_en.vhd tb/tb_counter_en.vhd
ghdl -e --std=08 tb_counter_en
ghdl -r --std=08 tb_counter_en --assert-level=error --vcd=counter_en.vcd
```

Message attendu : `COUNTER_EN: all 14 checks passed.`

Fin de simulation : `126 ns`.

### Générateur de clock enable

```bash
ghdl -a --std=08 rtl/clock_enable.vhd tb/tb_clock_enable.vhd
ghdl -e --std=08 tb_clock_enable
ghdl -r --std=08 tb_clock_enable --assert-level=error --vcd=clock_enable.vcd
```

Message attendu : `CLOCK_ENABLE: all 16 checks passed.`

Fin de simulation : `156 ns`.

### Détecteur de front montant

```bash
ghdl -a --std=08 rtl/edge_detector.vhd tb/tb_edge_detector.vhd
ghdl -e --std=08 tb_edge_detector
ghdl -r --std=08 tb_edge_detector --assert-level=error --vcd=edge_detector.vcd
```

Message attendu : `EDGE_DETECTOR: all 10 checks passed.`

Fin de simulation : `86 ns`.

### Synchroniseur à deux bascules

```bash
ghdl -a --std=08 rtl/sync_2ff.vhd tb/tb_sync_2ff.vhd
ghdl -e --std=08 tb_sync_2ff
ghdl -r --std=08 tb_sync_2ff --assert-level=error --vcd=sync_2ff.vcd
```

Message attendu : `SYNC_2FF: all 13 checks passed.`

Fin de simulation : `106 ns`.

### Visualiser les chronogrammes

Après génération des fichiers VCD :

```bash
gtkwave mux21.vcd
gtkwave adder_sub.vcd
gtkwave reg_en.vcd
gtkwave counter_en.vcd
gtkwave clock_enable.vcd
gtkwave edge_detector.vcd
gtkwave sync_2ff.vcd
```

Les assertions comparent automatiquement les sorties aux valeurs attendues. Les chronogrammes permettent d’examiner les transitions des signaux.

## Configuration de l’éditeur

Le fichier `vhdl_ls.toml` associe les sources RTL et les testbenches à une bibliothèque commune pour l’analyse dans l’éditeur :

```toml
standard = "2008"

[libraries]
defaultlib.files = [
    "rtl/*.vhd",
    "tb/*.vhd",
]
```

Cette configuration est indépendante de la compilation GHDL réalisée par le script Python.

## Périmètre et limites de vérification

| Module | Configuration testée | Limites principales |
|---|---|---|
| `mux21` | Huit combinaisons binaires | Valeurs non binaires non testées |
| `adder_sub` | `N = 8` | Opérandes non exhaustifs ; autres largeurs non testées |
| `reg_en` | `WIDTH = 8` | Autres largeurs non testées |
| `counter_en` | `WIDTH = 3` | Autres largeurs non testées |
| `clock_enable` | `DIVISOR = 4` | Autres diviseurs non testés |
| `edge_detector` | Scénarios dirigés sur une entrée synchrone | Transitions entre observations et valeurs non binaires non couvertes |
| `sync_2ff` | Scénarios logiques dirigés | Métastabilité physique et fiabilité matérielle non évaluées |

Les 72 vérifications ne constituent pas une mesure de couverture de code ou de couverture fonctionnelle. Leur réussite confirme les scénarios exécutés.

L’arrêt au premier échec du script Python a été contrôlé par injection temporaire d’un résultat attendu incorrect dans le testbench du multiplexeur.

## Fichiers générés

Les fichiers de travail GHDL et les traces de simulation sont produits localement et exclus du dépôt par `.gitignore`, notamment :

```gitignore
*.cf
*.vcd
*.o
```

Le dépôt conserve les sources RTL, les testbenches, les scripts et la documentation nécessaires pour reproduire les simulations.

## Prochaines étapes

- Anti-rebond sur une entrée synchronisée
- Étendre les tests aux cas limites et à plusieurs paramètres
- Machines à états
- FIFO synchrone et UART
- Vérification structurée avec VUnit ou cocotb
- Intégration d’un système pilotable par UART
- Synthèse, contraintes et analyse de timing
- Génération du bitstream et validation sur carte FPGA