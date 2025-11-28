/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: QDOM700
Autor-----------: ton R. Ghiraldelli
Data da Criacao-: 14/09/99
Descrição-------: 
Parametros------: NENHUM
Retorno---------: NENHUM
===============================================================================================================================
*/
User Function Qdom700()    // incluido pelo assistente de conversao do AP5 IDE em 26/11/99 

SetPrvt("CEDIT,CEDITOR,")

// O valor do cEdit e montado pelo parametro MV_QDTIPED e devera
//	conter um dos parametros abaixo
//cEdit:=Alltrim( cEdit )
//If cEdit == "WORD95"
//	cEditor := "TMsOleWord95"
//Elseif cEdit == "WORD97"
cEditor := "TMsOleWord97"
//ElseIf cEdit == "..."
//   cEditor := "..."       
//   Aqui deve-se colocar os elseif necessarios para determinar
//   qual o editor de texto deve-se usar.  Em 14 Set 1999 estao
//   disponiveis apenas no Word7(Office95) e Word8(Office97).
//EndIf
Return Alltrim( cEditor )
