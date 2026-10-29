# FPGA RTL to Bitstream

Conception de modules numériques en VHDL et construction progressive d’un flot FPGA, de la vérification RTL à la génération du bitstream.

Le dépôt rassemble les modules RTL, leurs testbenches auto-vérifiants et les instructions permettant de reproduire les simulations. Le développement se poursuit avec l’automatisation des tests, la synthèse, l’analyse de timing et la validation sur carte.

## État actuel

Trois modules RTL sont implémentés : deux modules combinatoires et un registre synchrone.

| Module | Description | Tests |
|---|---|---|
| `mux21` | Multiplexeur combinatoire 2 vers 1, sur un bit | 8 combinaisons binaires vérifiées par assertions |
| `adder_sub` | Additionneur/soustracteur combinatoire non signé, paramétrable en largeur | 4 cas dirigés sur 8 bits |
| `reg_en` | Registre paramétrable avec reset synchrone et enable | 7 vérifications dirigées prévues sur 8 bits |

Les simulations du multiplexeur et de l’additionneur/soustracteur ont été validées. Le registre compile ; l’exécution de son testbench reste à confirmer.

La synthèse, l’analyse de timing, la génération du bitstream et la validation sur carte constituent les prochaines phases du projet.

## Environnement

- **Système de développement :** Ubuntu 24.04 LTS
- **Langage :** VHDL-2008
- **Simulateur :** GHDL
- **Visualisation des chronogrammes :** GTKWave
- **Éditeur :** VS Code avec TerosHDL
- **Gestion de version :** Git et GitHub

Les outils `ghdl` et `gtkwave` doivent être accessibles depuis le terminal.

Pour consulter leurs versions :

```bash
ghdl --version
gtkwave --version
```

## Organisation du dépôt

```text
fpga-rtl-to-bitstream/
├── .gitignore
├── README.md
├── rtl/
│   ├── mux21.vhd
│   ├── adder_sub.vhd
│   └── reg_en.vhd
└── tb/
    ├── tb_mux21.vhd
    ├── tb_adder_sub.vhd
    └── tb_reg_en.vhd
```

- `rtl/` : descriptions matérielles destinées à la synthèse.
- `tb/` : bancs de test utilisés pour la simulation.

Les dossiers de scripts, de contraintes et de documentation seront complétés au fil du développement.

## Modules RTL

### Multiplexeur — `mux21`

Le multiplexeur sélectionne une entrée selon la valeur de `sel` :

| `sel` | Sortie |
|---|---|
| `'0'` | `y = a` |
| `'1'` | `y = b` |

Le circuit est combinatoire et ne possède ni horloge ni registre.

Le testbench applique les 8 combinaisons binaires de `a`, `b` et `sel`. Une assertion compare la sortie au résultat attendu pour chaque combinaison.

La détection d’erreur a également été contrôlée en modifiant temporairement un résultat attendu : le testbench a signalé l’écart et arrêté la simulation. Cette modification volontaire est retirée de la version finale.

Les tests couvrent les valeurs binaires `'0'` et `'1'`. Le comportement avec les autres valeurs de `std_logic`, notamment `'X'` et `'U'`, n’est pas vérifié.

### Additionneur/soustracteur — `adder_sub`

Le module réalise une opération arithmétique sur deux entrées de `N` bits :

| `sub` | Opération |
|---|---|
| `'0'` | `sum = a + b` |
| `'1'` | `sum = a - b` |

La largeur est définie par le générique `N`, dont la valeur par défaut est 8.

Les calculs utilisent le type `unsigned` du paquet IEEE `numeric_std`. Le résultat reste limité à `N` bits : les opérations sont réalisées modulo `2^N`, sans sortie de retenue ni indicateur de dépassement.

Le testbench vérifie quatre cas pour `N = 8` :

| Opération | Résultat attendu |
|---|---|
| `15 + 10` | `25` |
| `25 - 10` | `15` |
| `5 - 10` | `251`, résultat modulo 256 |
| `200 + 100` | `44`, résultat modulo 256 |

Les autres largeurs ne sont pas encore testées.

### Registre synchrone — `reg_en`

Le registre mémorise une donnée de `WIDTH` bits au front montant de l’horloge. La largeur par défaut est de 8 bits.

| Condition au front montant | Action |
|---|---|
| `rst = '1'` | Remettre `q` à zéro |
| `rst = '0'` et `en = '1'` | Charger `d` dans `q` |
| `rst = '0'` et `en = '0'` | Conserver la valeur précédente |

Le reset est synchrone, actif à l’état haut et prioritaire sur l’enable. Son activation entre deux fronts montants ne modifie pas immédiatement la sortie.

Le module ne définit pas de valeur initiale pour `q`. Le testbench applique un reset au début de la simulation.

Le testbench contient sept vérifications sur une instance de 8 bits :

1. Remise à zéro au front montant.
2. Chargement de la valeur 12 avec enable actif.
3. Conservation de la sortie lorsque l’entrée change entre les fronts montants.
4. Chargement de la valeur 25 au front montant suivant.
5. Conservation de la valeur lorsque l’enable est inactif.
6. Absence de remise à zéro avant le front montant.
7. Priorité du reset sur l’enable.

## Exécuter les simulations

Exécuter les commandes depuis la racine du dépôt.

L’option `--std=08` sélectionne VHDL-2008. Elle doit être utilisée pour l’analyse, l’élaboration et l’exécution.

### Multiplexeur

```bash
ghdl -a --std=08 rtl/mux21.vhd tb/tb_mux21.vhd
ghdl -e --std=08 tb_mux21
ghdl -r --std=08 tb_mux21 --assert-level=error --vcd=mux21.vcd
```

Message attendu :

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

Message attendu :

```text
All tests passed.
```

La dernière vérification a lieu à `40 ns`.

### Registre synchrone

```bash
ghdl -a --std=08 rtl/reg_en.vhd tb/tb_reg_en.vhd
ghdl -e --std=08 tb_reg_en
ghdl -r --std=08 tb_reg_en --assert-level=error --vcd=reg_en.vcd
```

Message attendu :

```text
REG_EN: all 7 checks passed.
```

La simulation doit se terminer à `46 ns`.

### Gestion des erreurs

L’option `--assert-level=error` arrête la simulation lorsqu’une assertion de niveau `error` ou supérieur échoue.

Un message de réussite concerne uniquement les vérifications exécutées par le testbench. Il ne constitue pas une preuve de correction pour tous les comportements possibles du circuit.

### Visualisation des chronogrammes

Après les simulations :

```bash
gtkwave mux21.vcd
gtkwave adder_sub.vcd
gtkwave reg_en.vcd
```

Les traces VCD permettent d’examiner les transitions des signaux. Les assertions assurent la vérification automatique des résultats attendus.

Pour le registre, afficher les signaux `clk_tb`, `rst_tb`, `en_tb`, `d_tb` et `q_tb`. Un affichage décimal non signé facilite la lecture des données.

## Périmètre de vérification

| Module | Périmètre actuel | Limites |
|---|---|---|
| `mux21` | Toutes les combinaisons des trois entrées binaires | Autres valeurs de `std_logic` non testées |
| `adder_sub` | Quatre cas dirigés sur 8 bits | Autres opérandes et largeurs non couverts exhaustivement |
| `reg_en` | Sept vérifications dirigées sur 8 bits | Exécution à confirmer ; autres largeurs non testées |

Le nombre de vérifications ne constitue pas une mesure de couverture de code ou de couverture fonctionnelle.

## Fichiers générés

Les fichiers de travail GHDL et les traces de simulation sont produits localement et exclus du dépôt par `.gitignore`, notamment :

```gitignore
*.cf
*.vcd
*.o
```

Le dépôt conserve les sources RTL, les testbenches et la documentation nécessaires pour reproduire les simulations.

## Prochaines étapes

- Validation du testbench et du chronogramme du registre
- Compteur synchrone avec enable
- Automatisation des simulations
- FIFO synchrone et UART
- Intégration des modules dans un système pilotable par UART
- Régression automatique avec GitHub Actions
- Synthèse, contraintes et analyse de timing
- Génération du bitstream et validation sur carte FPGA

Les fonctionnalités sont ajoutées progressivement, avec leurs tests et leur documentation.