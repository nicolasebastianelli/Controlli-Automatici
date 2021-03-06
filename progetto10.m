clear all;
close all;

%% PROGETTO DI CONTROLLI AUTOMATICI T
% Sebastianelli Nicola - 0000722894
% Serafini Filippo - 0000723678

% Si consideri il sistema descritto dalla funzione di trasferimento

s = tf('s');

N = 56700;
D = ((s+0.7)*(s+10)*(s+90)^2);
G = N/D;

figure(2)
margin(G);
hold on
grid on;

%% SPECIFICHE STATICHE
% 1) Errore a regime nullo in presenza di ingresso di riferimento a gradino di 
%    ampiezza massima pari a 2.0

% Per avere errore a regime nullo ho bisogno di un polo nell'origine

mu = 1;
Rs = mu/s;

% 2) Attenuazione superiore a 20 volte di un disturbo sinusoidale sull’uscita 
%    y(t) a pulsazione inferiore a 0.08 rad/s e di ampiezza massima pari a 0.3

% Controllo quali valore assume la funzione Ge alla pulsazione w = 0.08

Ge = G * Rs;

w = 0.08;
[m, p] = bode(Ge, w);
m_db = 20*log10(m);

% Per rispettare la specifica devo inserire un opportuno guadagno al 
% regolatore statico. Mi appoggio alla funzione di sensitivita 
% S(s) = 1 / (1 + R(s)*G(s))
% che lega disturbo e uscita in questo modo: Y(s) = S(s)*D(s)

attenuation_db = 20*log10(19);
mu_db = attenuation_db - m_db;
mu = 10^(mu_db/20);
mu = 1.7;
Rs = mu/s;
Ge = G * Rs;
F = Ge / (1 + Ge);

% figure(1)
% step(F)
% hold on
figure(2)
margin(Ge)
grid on
hold on

%% SPECIFICHE DINAMICHE
% 1) Assenza di sovraelongazione e oscillazioni nella risposta al 
%    riferimento a gradino.
% 2) Tempo di assestamento al 5% della risposta al riferimento a gradino
%    inferiore a 0.4s.
% 3) Margine di fase superiore a 45 gradi , per garantire robustezza.

% Per avere sovraelongazione nulla è richiesto un coefficiente di 
% smorzamento delta > 0.7, e poichè delta = Mf/100, dovremo ottenere un
% Margine di Fase Mf > 70°. Per non restare troppo vicini a questo limite
% decidiamo di voler raggiungere un margine di fase Mf > 75°.

% Per alzare il margine di fase abbiamo bisogno di una rete anticipatrice.

% Progetto la rete per cancellazione
% Fisso tau in modo da cancellare il polo della G e scelgo un Wc.

tau = 1 /0.7;
Wc = 7.5;
Rd = (1 + tau*s);

Rfb = Rs*Rd;

L = G * Rfb;
F = L/(1+L);

figure(1)
step(F)
hold on
grid on

figure(2)
bode(L)
grid on

% (9.5.1.1)
% A questo punto devo diminuire il tempo di assestamento per rispettare la
% specifica. Per farlo utilizzo un regolatore Feedforward

Rff = ((1 + (1/0.7)*s)*(1 + (1/10)*s))/((1 + 1/100*s)^2);
F = (L/(1+L))+((G*Rff)/(1 + L));
Q = (Rd*Rs+Rff)/(1+L);

figure(1)
step(F)

figure(3)
bode(Q)
grid on
hold on

% L'introduzione del regolatore Feedforward ha causato un forte
% innalzamento della funzione di sensività del controllo Q(s). Proviamo ad
% abbassarlo nuovamente introducento un pre-filtro del secondo ordinte.

t = 0.65/Wc;
Rpf = 1/((1+t*s)*(1+t*s));
F = (G*Rpf*(Rff+Rs*Rd))/(1 + G*Rs*Rd);
Q = (Rpf*(Rff+Rs*Rd))/(1 + G*Rs*Rd);

figure(1)
step(F)
stepinfo(F)
grid on

figure(3)
bode(Q)
grid on

% Anti windup
TAU = [1 0.7];
[num,den] = tfdata(Rfb, 'v');

aw1 = tf(num,TAU);
aw2 = tf(TAU-den,TAU);
