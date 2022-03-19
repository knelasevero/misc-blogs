# Máquina do tempo de pacotes Archlinux

Vou começar por dizer que o que vou ensinar aqui não é o ideal para condições normais de se usar uma distribuição Linux Rolling Release/Bleeding Edge. Mas é inevitável cair em situações que pedem esse tipo de solução.

Vou falar de como reverter upgrades catastróficos, e disponibilizar alguns utilitários que vão facilitar a sua vida no futuro.


<br>

## Table of Contents

* [1 - Requisitos](#reqs)
* [2 - Motivação](#motiv)
* [3 - O que causou o problema](#causa)
* [4 - Cenário e solução rápida](#cenario)
* [5 - Caso o pacote não esteja no cache](#nocache)
* [6 - Caso o pacote não esteja em nenhum cache](#nonocache)

<br>

<a name="reqs"></a>
## [1 - Requisitos](#reqs)

* Esse guia é pra qualquer pessoa usando alguma distribuição que seja Archlinux based (Manjaro, Novo SteamOS, EndeavourOS, Garuda, etc), então você obviamente precisa desse sistema instalado
* É necessária alguma familiaridade com Linux, comandos genéricos do Linux, gerenciadores de pacote (pacman, AUR helpers) e outros conceitos introdutórios 
* De maneira geral já ter feito alguns upgrades de pacotes no passado, para que o cache do pacman tenha algumas versões guardadas

<br>

<a name="motiv"></a>
## [2 - Motivação](#motiv)

Provavelmente você chegou nesse guia por estar procurando uma solução para algum upgrade que fez quebrar todo seu sistema. Isso é mais frequente se você usa alguma máquina com componentes um pouco incomuns, como laptops gamers com placas de rede diferenciadas, ou placas de vídeo muito recentes. É possível acabar aqui também simplesmente por pacotes quebrados, pois sempre apontar para versões mais recentes vai acabar tendo esse risco (com a vantagem de ter soluções mais rápido também), e upgrades frequentes fazem parte das boas práticas de usar um Arch based.

No meu caso atualmente, tenho um laptop gamer muito recente que tem uma placa de rede wifi mediatek que frequentemente me dá dor de cabeça com atualizações do Kernel. Também ocasionalmente tenho que trabalhar com virtualização, e novas versões do kvm ou virtualbox me fazem passar raiva.

Mas não tentar atualizar não é uma opção saudável. É necessário estar sempre atualizado, na medida do possível, para evitar tretas de segurança e até para fazer algo minimamente funcionar. Eu disse que tenho problemas com upgrades referentes a minha placa de rede, mas em versões antigas do Kernel minha placa de rede nem funciona. Então essa dinâmica de tentar fazer upgrade e ter que tentar voltar um pouco é o que vou tratar aqui.

<br>
<a name="causa"></a>
## [3 - O que causou o problema](#causa)

O maior "culpado" aqui provavelmente vai ser o `pacman -Syu` que vai fazer um system wide upgrade, ou seja, vai fazer um upgrade de todos os seus pacotes. É recomendado fazer esse tipo de upgrade com uma frequencia grande, justamente para não pegar um bloco grande demais de modificações. Fazer toda semana, ou todo dia, vai te fazer ter que lidar com poucas tretas de cada vez. Nem sempre isso é possível, e quando junta muita coisa, a chance de dar algo errado é muito grande. Achar um pacote que não funciona contigo em versões mais novas vai começar a fazer o seu sistema pessoal virar um snowflake, então é bom reportar os problemas e frequentemente tentar refazer o upgrade pra versões ainda mais novas pra ver se volta a funcionar atualizado.


<br>

<a name="cenario"></a>
## [4 - Cenário e solução rápida](#cenario)

Digamos que você fez um upgrade geral no dia anterior, tudo parecia funcionar tranquilo e você desligou o computador. Hoje você liga o computador e não consegue mais se conectar a sua wifi. Além disso você nota incontáveis outros pacotes não funcionando. Hora de voltar no tempo.

Pra te dar uma solução rápida, rode o seguinte script provendo as infromações necessárias (adaptado de https://linuxconfig.org/how-to-rollback-pacman-updates-in-arch-linux):

```
cat > revert-upgrade.sh <<EOF
if [ -z "\$PAST_DATE" ]
then
    echo "If you want to suppress this input, run 'export PAST_DATE=<PAST_DATE>' on the command line"
    echo -n 'Input PAST_DATE: '
    read -r PAST_DATE
fi
grep -a upgraded /var/log/pacman.log| grep \$PAST_DATE > /tmp/lastupdates.txt                                                              
awk '{print \$4}' /tmp/lastupdates.txt > /tmp/lines1;awk '{print \$5}' /tmp/lastupdates.txt | sed 's/(/-/g' > /tmp/lines2
paste /tmp/lines1 /tmp/lines2 > /tmp/lines
tr -d "[:blank:]" < /tmp/lines > /tmp/packages
cd /var/cache/pacman/pkg/
for i in \$(cat /tmp/packages); do sudo pacman --noconfirm -U "\$i"*; done
EOF
```

Se você exportar a variável de ambiente PAST_DATE o script vai rodar para essa data, se você não exportar, ele vai te perguntar. Para rodar basta fazêlo executável e chamar no seu shell:

```
chmod +x revert-upgrade.sh
./revert-upgrade.sh
```

A data tem que ser provida no formato AAAA-MM-DD.

<br>

<a name="nocache"></a>
## [5 - Caso o pacote não esteja no cache do pacman](#nocache)

Se você limpou o cache do pacman, ou se por algum outro motivo o pacote antigo não estiver em `/var/cache/pacman/pkg`, você receberá uma mensagem de erro para o script anterior, algo como `error: 'PACKAGE-x.x.x-1*': could not find or read package`. Mas pode ser que o pacote foi instalado com algum AUR helper, e o cache vai estar em outro lugar. Para o yay (você terá que adapatar se usar outro AUR helper) podemos achar o cache em `~/.cache/yay/PACOTE/*`. Veja a versao que está em /tmp/packages do script anterior e instale com `yay -U ~/.cache/yay/PACOTE/PACOTE-versao*`.


<br>

<a name="nonocache"></a>
## [6 - Caso o pacote não esteja em nenhum cache](#nonocache)

 O AUR não tem um archive oficial, já que vários de seus pacotes são buildados dinamicamente no momento da instalação. Mas pacotes dos repositórios oficiais tem um archive com muitas versões antigas para que a gente possa instalar caso seja necessário. Para navegar no archive, basta acessar https://archive.archlinux.org/packages/. Está organizado em ordem alfabética, e se trata de simplemente selecionar o pacote e sua versão na arquitetura do seu computador (provavelmnete x86_64). Para instalar diretamente com o link você pode rodar (adaptando a URL/nome):

```
sudo pacman -U https://archive.archlinux.org/packages/path/packagename.pkg.tar.xz
```