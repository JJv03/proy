#!/bin/bash
#845097, Valle Morenilla, Juan, T, 1, A
#839757, Ye, Ming Tao, T, 1, A

# LIMPIEZA DE TABLAS EN IPTABLES
# # Inicializamos tabla filter
iptables -F                 # Eliminar reglas de filtrado (pero no las personalizadas)
iptables -X                 # Eliminar cadenas personalizadas definidas por el usuario (pero no las default)
iptables -Z                 # Reestablecer contadores de la tabla filter
iptables -t nat -F          # Eliminar reglas de traducción de direcciones de red en tabla nat

iptables -P INPUT DROP      # Bloqueamos todo el tráfico no especificado por reglas
iptables -P FORWARD DROP    # Bloqueamos todo el tráfico no especificado por reglas

# Los paquetes que no se hayan permitido explícitamente, los regitramos (opcional)
iptables -A INPUT -i enp0s3 -j LOG      #Guarda registro entradas
iptables -A FORWARD -i enp0s3 -j LOG    #Guarda registro redirecciones

#Acceso a RI1, RI2, RI3 (Redes internas)
iptables -t nat -A POSTROUTING -s 192.168.51.0/24 -o enp0s3 -j MASQUERADE   #Red Interna 1
iptables -t nat -A POSTROUTING -s 192.168.52.0/24 -o enp0s3 -j MASQUERADE   #Red Interna 2
iptables -t nat -A POSTROUTING -s 192.168.53.0/24 -o enp0s3 -j MASQUERADE   #Red Interna 3

#Todo lo que salga fuera de extranet tendrá la IP de debian1
iptables -t nat -A POSTROUTING -o enp0s3 -j SNAT --to 192.168.50.2  #IP debian1
iptables -t nat -A POSTROUTING -o enp0s8 -j SNAT --to 192.168.50.2  #IP debian1

#Se redireccionan las peticiones desde NAT, si es al servidor web de debian2 o al servidor ssh de debian5
iptables -t nat -A PREROUTING -i enp0s3 -p tcp --dport 80 -j DNAT --to 192.168.51.2:80  #RI1
iptables -t nat -A PREROUTING -i enp0s3 -p tcp --dport 22 -j DNAT --to 192.168.53.2:22  #RI3

#Se redireccionan las peticiones desde host, si es al servidor web de debian2 o al servidor ssh de debian5
iptables -t nat -A PREROUTING -i enp0s8 -p tcp --dport 80 -j DNAT --to 192.168.51.2:80  #RI1
iptables -t nat -A PREROUTING -i enp0s8 -p tcp --dport 22 -j DNAT --to 192.168.53.2:22  #RI3

#Se permite pasar trafico hacia extranet (servidor ssh y servidor web)
iptables -A FORWARD -i enp0s3 -p all -j ACCEPT
iptables -A FORWARD -i enp0s8 -p all -j ACCEPT

#Se permite hacia las redes internas 1 y 2
iptables -A FORWARD -i enp0s9 -p all -j ACCEPT
iptables -A FORWARD -i enp0s10 -p all -j ACCEPT

#Se permite el tráfico por el puerto 80 hacia debian2 y por el puerto 22 hacia debian5 (servidor ssh) 
iptables -A FORWARD -p tcp --dport 80 -d 192.168.51.2 -j ACCEPT
iptables -A FORWARD -p tcp --dport 22 -d 192.168.53.2 -j ACCEPT

#Se permite la entrada de todo el tráfico local (intranet)
iptables -A INPUT -i lo -p all -j ACCEPT        #Loopback
iptables -A INPUT -i enp0s9 -p all -j ACCEPT    #RI1
iptables -A INPUT -i enp0s10 -p all -j ACCEPT   #RI2

#Aceptamos cualquier ping entre máquinas pero no aquellos que vengan de host
iptables -A INPUT -i enp0s8 -p icmp --icmp-type echo-request -j DROP
iptables -A INPUT -i enp0s9 -p icmp --icmp-type echo-request -j ACCEPT
iptables -A INPUT -i enp0s10 -p icmp --icmp-type echo-request -j ACCEPT

# Guardamos reglas que hemos creado
iptables-save > /etc/iptables/rules.v4
