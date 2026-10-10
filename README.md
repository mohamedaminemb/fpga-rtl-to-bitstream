# FPGA RTL to Bitstream

Conception de modules numériques en VHDL et construction progressive d’un flot FPGA, de la vérification RTL à la génération du bitstream.

Le dépôt contient les modules RTL, leurs testbenches auto-vérifiants et les instructions permettant de reproduire les simulations. Il sera enrichi progressivement avec l’automatisation des tests, la synthèse, l’analyse de timing et la validation sur carte.

## État actuel

Deux modules combinatoires sont implémentés :

| Module | Description | Vérification |
|---|---|---|
| `mux21` | Multiplexeur 2 vers 1, sur un bit | Testbench avec assertions couvrant les 8 combinaisons binaires |
| `adder_sub` | Additionneur/soustracteur non signé, paramétrable en largeur | Testbench avec 4 cas dirigés, pour une largeur de 8 bits |

La synthèse, l’analyse de timing, la génération du bitstream et la validation sur carte ne sont pas encore réalisées.

## Environnement

- **Système de développement :** Ubuntu 24.04 LTS
- **Langage :** VHDL, compilé avec le standard VHDL-2008
- **Simulateur :** GHDL
- **Visualisation des chronogrammes :** GTKWave
- **Éditeur :** VS Code avec TerosHDL
- **Gestion de version :** Git et GitHub

Pour connaître les versions installées :

```bash
ghdl --version
gtkwave --version
```

## Structure actuelle

```text
fpga-rtl-to-bitstream/
├── .gitignore
├── README.md
├── rtl/
│   ├── mux21.vhd
│   └── adder_sub.vhd
└── tb/
    ├── tb_mux21.vhd
    └── tb_adder_sub.vhd
```

Le dossier `rtl/` contient les descriptions matérielles. Le dossier `tb/` contient les bancs de test utilisés uniquement pour la simulation.

## Modules

### Multiplexeur : `mux21`

Le multiplexeur sélectionne une entrée selon la valeur de `sel` :

- Si `sel = '0'`, alors `y = a`.
- Si `sel = '1'`, alors `y = b`.

Le circuit est combinatoire : il ne possède ni horloge ni registre.

Son testbench applique les 8 combinaisons binaires de `a`, `b` et `sel`, puis vérifie chaque résultat avec une assertion.

La capacité du testbench à détecter une erreur a également été vérifiée : un résultat attendu volontairement incorrect a provoqué une erreur d’assertion et l’arrêt de la simulation. Cette modification temporaire est ensuite retirée.

Ces tests couvrent les combinaisons de `'0'` et `'1'`, sans vérifier les autres valeurs de `std_logic`, telles que `'X'` ou `'U'`.

### Additionneur/soustracteur : `adder_sub`

Le module réalise une opération arithmétique sur deux entrées de `N` bits :

- Si `sub = '0'`, alors `sum = a + b`.
- Si `sub = '1'`, alors `sum = a - b`.

La largeur est définie par le générique `N`, dont la valeur par défaut est 8.

Les calculs utilisent le type `unsigned` du paquet IEEE `numeric_std`. Le résultat reste limité à `N` bits : les opérations sont donc réalisées modulo `2^N`, sans sortie de retenue ni indicateur de dépassement.

Le testbench vérifie les cas suivants pour `N = 8` :

| Opération | Résultat attendu |
|---|---|
| `15 + 10` | `25` |
| `25 - 10` | `15` |
| `5 - 10` | `251`, soit le résultat modulo 256 |
| `200 + 100` | `44`, soit le résultat modulo 256 |

Les autres largeurs ne sont pas encore testées.

## Exécuter les simulations

Exécuter les commandes depuis la racine du dépôt. Utiliser `--std=08` pour l’analyse, l’élaboration et l’exécution.

### Multiplexeur

```bash
ghdl -a --std=08 rtl/mux21.vhd tb/tb_mux21.vhd
ghdl -e --std=08 tb_mux21
ghdl -r --std=08 tb_mux21 --assert-level=error --vcd=mux21.vcd
```

Si les 8 vérifications réussissent, le testbench affiche :

```text
MUX: all 8 binary cases passed.
```

La simulation se termine à `80 ns`.

### Additionneur/soustracteur

```bash
ghdl -a --std=08 rtl/adder_sub.vhd tb/tb_adder_sub.vhd
ghdl -e --std=08 tb_adder_sub
ghdl -r --std=08 tb_adder_sub --assert-level=error --vcd=adder_sub.vcd
```

Si les 4 vérifications réussissent, le testbench affiche :

```text
All tests passed.
```

La dernière vérification a lieu à `40 ns`.

### Détection des erreurs

L’option `--assert-level=error` arrête la simulation lorsqu’une assertion de niveau `error` ou supérieur échoue. Le diagnostic indique le problème rencontré.

### Visualisation

Après les simulations :

```bash
gtkwave mux21.vcd
gtkwave adder_sub.vcd
```

Les fichiers VCD servent à examiner les transitions des signaux. Les assertions assurent la vérification automatique des résultats.

## Fichiers générés

Les fichiers de travail GHDL et les traces VCD sont générés localement et exclus du dépôt par `.gitignore`.

Le dépôt conserve le code source, les testbenches et la documentation nécessaires pour reproduire les simulations.

## Suite prévue

- Registre synchrone et compteur avec enable
- Automatisation des simulations
- FIFO synchrone et UART
- Régression automatique avec intégration continue
- Synthèse et analyse de timing
- Implémentation et validation sur carte FPGA

Cette liste décrit les objectifs futurs, pas les fonctionnalités déjà disponibles.