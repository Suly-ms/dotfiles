#!/bin/bash
# --- A MODIFIER ---
GITHUB_USER="votre_pseudo_github_ici"
GITHUB_REPO="dotfiles"
# ------------------

GREEN='\033[0;32m'
NC='\033[0m' 

echo -e "${GREEN}### Installation Debian + XFCE + Zsh (Mode Propre) ###${NC}"

# 1. Pré-requis
echo -e "${GREEN}[+] Maj système et installation Git/Zsh/Curl...${NC}"
sudo apt update && sudo apt install -y git zsh curl

# 2. Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo -e "${GREEN}[+] Installation de Oh My Zsh...${NC}"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# 3. Clonage Git Bare
echo -e "${GREEN}[+] Récupération des dotfiles...${NC}"
if [ ! -d "$HOME/.cfg" ]; then
    git clone --bare "https://github.com/$GITHUB_USER/$GITHUB_REPO.git" $HOME/.cfg
fi

function config {
   /usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME "$@"
}

# 4. GESTION DES CONFLITS (Version Corrigée)
echo -e "${GREEN}[+] Résolution des conflits et Backup...${NC}"
mkdir -p $HOME/.config-backup

# Regex corrigée : attrape les fichiers cachés ET non-cachés (comme install.sh)
conflicting_files=$(config checkout 2>&1 | egrep "^\s+" | awk {'print $1'})

for file in $conflicting_files; do
    echo "Backup de : $file"
    mkdir -p "$HOME/.config-backup/$(dirname "$file")"
    mv "$HOME/$file" "$HOME/.config-backup/$file"
done

# Application de la config
echo -e "${GREEN}[+] Application de la configuration...${NC}"
config checkout
config config --local status.showUntrackedFiles no

# 5. INSTALLATION DES LOGICIELS (Mode "Liste Curée")
if [ -f "$HOME/mes_logiciels.txt" ]; then
    echo -e "${GREEN}[+] Installation de vos logiciels favoris...${NC}"
    
    # On lit le fichier, on ignore les commentaires (#) et les lignes vides
    # On remplace les retours à la ligne par des espaces pour faire une seule commande apt
    APPS=$(grep -vE "^\s*#" $HOME/mes_logiciels.txt | tr "\n" " ")
    
    if [ ! -z "$APPS" ]; then
        sudo apt install -y $APPS
    else
        echo "La liste de logiciels est vide."
    fi
else
    echo "Pas de fichier mes_logiciels.txt trouvé."
fi

# 6. Finalisation Zsh et Plugins
echo -e "${GREEN}[+] Configuration avancée de Zsh...${NC}"

# Changer le shell
sudo chsh -s $(which zsh) $USER

# Installation de l'outil Zoxide (nécessaire pour le plugin zsh)
sudo apt install -y zoxide

# Définition du dossier custom
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"

# A. Thème Powerlevel10k
if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
    echo "Installation du thème Powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k
fi

# B. Plugins
echo "Installation des plugins Zsh..."

# Autosuggestions
[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] && git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions

# Syntax Highlighting
[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting

# You Should Use
[ ! -d "$ZSH_CUSTOM/plugins/you-should-use" ] && git clone https://github.com/MichaelAquilina/zsh-you-should-use.git $ZSH_CUSTOM/plugins/you-should-use

# Zsh Bat
[ ! -d "$ZSH_CUSTOM/plugins/zsh-bat" ] && git clone https://github.com/fdellwing/zsh-bat.git $ZSH_CUSTOM/plugins/zsh-bat

echo -e "${GREEN}### TERMINÉ ! Redémarrez votre session. ###${NC}"
