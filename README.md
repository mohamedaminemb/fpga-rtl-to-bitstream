#FPGA RTL to Bitstream 

Projet fil rouge de conception VHDL synthétisable, vérification RTL et sous-ensemble de flot FPGA.


## 🛠️ Chaîne d'outils (Toolchain)

---

- **OS** : Ubuntu 24.04 LTS 
- **Simulateur VHDL** : GHDL (Standard VHDL-2008) 
- **Visualiseur de formes d'onde (Waveform Viewer)** : GTKWave 
- **Éditeur / Linter** : VS Code + TerosHDL 
- **Gestion de version** : Git &amp; GitHub

---

## 📁 Structure du dépôt

```text
fpga-rtl-to-bitstream/ 
├── rtl/          # Modules VHDL synthétisables (DUT) 
├── tb/           # Bancs de test (Testbenches non synthétisables) 
├── scripts/      # Scripts d'automatisation (Simulation / Synthèse) 
├── constraints/  # Contraintes d'horloge et de broches (XDC/SDC) 
└── docs/         # Documentation et rapports de timing/ressources

## Exécuter la simulation

Pour compiler et simuler le multiplexeur 2 vers 1 sous GHDL :

# 1. Analyse (Compilation syntaxique) 
ghdl -a rtl/mux21.vhd 
ghdl -a tb/tb_mux21.vhd 

# 2. Élaboration 
ghdl -e tb_mux21 

# 3. Exécution et génération du fichier VCD 
ghdl -r tb_mux21 --vcd=mux21.vcd 

# 4. Visualisation du chronogramme 
gtkwave mux21.vcd
