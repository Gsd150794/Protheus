/*
===============================================================================================================================
                          ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |    Data    |                                             Motivo                                          
-------------------------------------------------------------------------------------------------------------------------------
              |            |
===============================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
#Include "TopConn.ch"
#Include "APWEBSRV.CH"
#Include "TBICONN.CH"   
#Include "RESTFUL.CH"

/*
===============================================================================================================================
Programa----------: MOMS065
Autor-------------: Igor Fricks Melgaço
Data da Criacao---: 16/05/2022
===============================================================================================================================
Descrição---------: Processamento do arquivo de Ncm do portal. Chamado 39487.
===============================================================================================================================
Parametros--------: Nenhum
=========================================ZP1======================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS065(lAuto)
Default lAuto := .T.

   If lAuto
      PREPARE ENVIRONMENT EMPRESA '01' FILIAL '01';
      TABLES "SYD";
      MODULO 'OMS'

      MOMS065B()

      RESET ENVIRONMENT
   Else
      FWMsgRun(,{|oproc|  MOMS065B() },'Aguarde processamento...','Lendo dados...')
   EndIf

Return .T.



/*
===============================================================================================================================
Programa----------: MOMS065B
Autor-------------: Igor Fricks Melgaço
Data da Criacao---: 17/05/2022
===============================================================================================================================
Descrição---------: Importa os dados do arquivo. Chamado 39487.
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS065B(lAuto)
Local dDtNcm     := Ctod("")
Local i          := 0
Local _oJson
Local _cRetHttp  := ""
Local _cRet      := ""
Local _cJSonRet  := Nil 
Local _nTimOut	  := 120
Local _cLinkWS   := ""
Local _cGetParms := "perfil=PUBLICO"
Local _aHeadOut   := {}
Local _cDesc := ""
Local cNcm := ""

dDtNcm     := U_ItGetMV( 'IT_DTNCM' , CTOD("01/01/2001") )
_cLinkWS   := U_ItGetMV( 'IT_SISCOM' ,"https://portalunico.siscomex.gov.br/classif/api/publico/nomenclatura/download/json")

aAdd(_aHeadOut,'Content-Type: application/json') 

_cRetHttp   := MOMS065C(AllTrim(HttpGet( _cLinkWS, _cGetParms, _nTimOut, _aHeadOut, @_cJSonRet)),.T.)
_oJson      := JsonObject():new()
_cRet       := _oJson:FromJson(_cRetHttp)

If ctod(_oJson:GetJsonObject("Data_Ultima_Atualizacao_NCM")) > dDtNcm 

   PutMV( 'IT_DTNCM' , cTod(_oJson:GetJsonObject("Data_Ultima_Atualizacao_NCM")) )

   If ! ValType(_cRet) == "U"
      _cMsgErro := "[FALSO] Erro ao popular o JSon de retorno da Cia do Leite. Problemas no JSon de retorno."
      Break
   EndIf

   _aNames := _oJson:GetNames()
   _oDados := _oJson:GetJsonObject("Nomenclaturas")

   DBSelectArea("SYD")

   If ! ValType(_oDados) == "J"

      For i := 1 to Len(_oDados)

         If Len(_oDados[i]:GetJsonObject("Codigo")) = 10 .And. !Empty(AllTrim(_oDados[i]:GetJsonObject("Descricao")))

            cNcm := AllTrim(StrTran(_oDados[i]:GetJsonObject("Codigo"),".",""))

            SYD->(DBSetOrder(1))
            If SYD->(!DBSeek(xFilial("SYD")+cNcm))

               _cDesc := decodeutf8(_oDados[i]:GetJsonObject("Descricao"),"cp1252")

               If ValType(_cDesc) == "U"
                  _cDesc := MOMS065C(Upper(_oDados[i]:GetJsonObject("Descricao"))) 
               Else
                  _cDesc := MOMS065C(Upper(_cDesc))
               EndIf

               RecLock("SYD",.T.)
                  SYD->YD_TEC      := cNcm
                  SYD->YD_DESC_P   := _cDesc
                  SYD->YD_I_DTINC  := cTod(_oDados[i]:GetJsonObject("Data_Inicio"))
                  SYD->YD_I_DTFIM  := cTod(_oDados[i]:GetJsonObject("Data_Fim"))
                  SYD->YD_I_ORIGE  := "MOMS065"
               MSUnLock()
            Else
               If _oDados[i]:GetJsonObject("Data_Fim") <> "31/12/9999"
                  RecLock("SYD",.F.)
                     SYD->YD_I_DTFIM  := cTod(_oDados[i]:GetJsonObject("Data_Fim"))
                     SYD->YD_I_ORIGE  := "MOMS065"
                  MSUnLock()
               EndIf
            EndIf
         EndIf
      Next

   EndIf
EndIf

Return .T.


/*
===============================================================================================================================
Programa----------: MOMS065C
Autor-------------: Igor Fricks Melgaço
Data da Criacao---: 17/05/2022
===============================================================================================================================
Descrição---------: Converte os caracteres especiais. Chamado 30177.
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS065C(cRetorno,lXML)
Local cCarac := U_ItGetMV( 'IT_CARVAL'," ABCDEFGHIJKLMNOPQRSTUVXYZ1234567890()/\{}[]=+-_%$#@!?:;")
Local i := 0
Local cRet := ""

Default lXML := .F.

If lXML

   cRetorno:=StrTran(cRetorno,"Ãndia","India") 
   cRetorno:=StrTran(cRetorno,"Ã­mÃ£s","imas") 
   cRetorno:=StrTran(cRetorno,"Ã¡","a") //á
   cRetorno:=StrTran(cRetorno,"Ã?","A") //Á
   cRetorno:=StrTran(cRetorno,"Ã©","e") //é
   cRetorno:=StrTran(cRetorno,"Ã‰","E") //É
   cRetorno:=StrTran(cRetorno,"Ã?","I") //Í
   cRetorno:=StrTran(cRetorno,"Ã³","o") //ó
   cRetorno:=StrTran(cRetorno,"Ã“","O") //Ó
   cRetorno:=StrTran(cRetorno,"Ãº","u") //ú
   cRetorno:=StrTran(cRetorno,"Ã£","a") //ã
   cRetorno:=StrTran(cRetorno,"Ã¢","a") //â
   cRetorno:=StrTran(cRetorno,"Ãµ","o") //õ
   cRetorno:=StrTran(cRetorno,"Ã¢","a") //â
   cRetorno:=StrTran(cRetorno,"Ãª","e") //ê
   cRetorno:=StrTran(cRetorno,"Ã´","o") //ó
   cRetorno:=StrTran(cRetorno,"Ã§","c") //ç
   cRetorno:=StrTran(cRetorno,"Âº","o") //º
   cRetorno:=StrTran(cRetorno,"Â %","%") //%
   cRetorno:=StrTran(cRetorno,"Â Â°","o") //°
   cRetorno:=StrTran(cRetorno,"Ã","i") //í

   cRet := cRetorno
Else
   cRetorno:=StrTran(cRetorno,"Ã?","E")
   cRetorno:=StrTran(cRetorno,"Ã^","E")
   cRetorno:=StrTran(cRetorno,"^","")
   cRetorno:=StrTran(cRetorno,"á","a")
   cRetorno:=StrTran(cRetorno,"Á","A")
   cRetorno:=StrTran(cRetorno,"à","a")
   cRetorno:=StrTran(cRetorno,"À","A")
   cRetorno:=StrTran(cRetorno,"ã","a")
   cRetorno:=StrTran(cRetorno,"Ã","A")
   cRetorno:=StrTran(cRetorno,"â","a")
   cRetorno:=StrTran(cRetorno,"Â","A")
   cRetorno:=StrTran(cRetorno,"ä","a")
   cRetorno:=StrTran(cRetorno,"Ä","A")
   cRetorno:=StrTran(cRetorno,"é","e")
   cRetorno:=StrTran(cRetorno,"É","E")
   cRetorno:=StrTran(cRetorno,"ë","e")
   cRetorno:=StrTran(cRetorno,"Ë","E")
   cRetorno:=StrTran(cRetorno,"ê","e")
   cRetorno:=StrTran(cRetorno,"Ê","E")
   cRetorno:=StrTran(cRetorno,"í","i")
   cRetorno:=StrTran(cRetorno,"Í","I")
   cRetorno:=StrTran(cRetorno,"ï","i")
   cRetorno:=StrTran(cRetorno,"Ï","I")
   cRetorno:=StrTran(cRetorno,"î","i")
   cRetorno:=StrTran(cRetorno,"Î","I")
   cRetorno:=StrTran(cRetorno,"ý","y")
   cRetorno:=StrTran(cRetorno,"Ý","y")
   cRetorno:=StrTran(cRetorno,"ÿ","y")
   cRetorno:=StrTran(cRetorno,"ó","o")
   cRetorno:=StrTran(cRetorno,"Ó","O")
   cRetorno:=StrTran(cRetorno,"õ","o")
   cRetorno:=StrTran(cRetorno,"Õ","O")
   cRetorno:=StrTran(cRetorno,"ö","o")
   cRetorno:=StrTran(cRetorno,"Ö","O")
   cRetorno:=StrTran(cRetorno,"ô","o")
   cRetorno:=StrTran(cRetorno,"Ô","O")
   cRetorno:=StrTran(cRetorno,"ò","o")
   cRetorno:=StrTran(cRetorno,"Ò","O")
   cRetorno:=StrTran(cRetorno,"ú","u")
   cRetorno:=StrTran(cRetorno,"Ú","U")
   cRetorno:=StrTran(cRetorno,"ù","u")
   cRetorno:=StrTran(cRetorno,"Ù","U")
   cRetorno:=StrTran(cRetorno,"ü","u")
   cRetorno:=StrTran(cRetorno,"Ü","U")
   cRetorno:=StrTran(cRetorno,"ç","c")
   cRetorno:=StrTran(cRetorno,"Ç","C")
   cRetorno:=StrTran(cRetorno,"º","o")
   cRetorno:=StrTran(cRetorno,"°","o")
   cRetorno:=StrTran(cRetorno,"ª","a")
   cRetorno:=StrTran(cRetorno,"ñ","n")
   cRetorno:=StrTran(cRetorno,"Ñ","N")
   cRetorno:=StrTran(cRetorno,"²","2")
   cRetorno:=StrTran(cRetorno,"³","3")
   cRetorno:=StrTran(cRetorno,"’","'")
   cRetorno:=StrTran(cRetorno,"§","S")
   cRetorno:=StrTran(cRetorno,"±","+")
   cRetorno:=StrTran(cRetorno,"­","-")
   cRetorno:=StrTran(cRetorno,"´","'")
   cRetorno:=StrTran(cRetorno,"o","o")
   cRetorno:=StrTran(cRetorno,"µ","u")
   cRetorno:=StrTran(cRetorno,"¼","1/4")
   cRetorno:=StrTran(cRetorno,"½","1/2")
   cRetorno:=StrTran(cRetorno,"¾","3/4")
   cRetorno:=StrTran(cRetorno,"&","e") 
   cRetorno:=StrTran(cRetorno,";",",")
   cRetorno:=StrTran(cRetorno,"¡","i")
   cRetorno:=StrTran(cRetorno,"©","c.")
   cRetorno:=StrTran(cRetorno,"®","r.")
   cRetorno:=StrTran(cRetorno,"£","L")
   cRetorno:=StrTran(cRetorno,"‡","t")
   cRetorno:=StrTran(cRetorno,"ƒ","f")
   cRetorno:=StrTran(cRetorno,"–","-")
   cRetorno:=StrTran(cRetorno,"!","")
   cRetorno:=StrTran(cRetorno,"×","x")
   cRetorno:=StrTran(cRetorno,"¥","")
   cRetorno:=StrTran(cRetorno,"¤","")
   cRetorno:=StrTran(cRetorno," -- ","")
   cRetorno:=StrTran(cRetorno,"-- ","")
   cRetorno:=StrTran(cRetorno,"- ","")
   cRetorno:=StrTran(cRetorno,Chr(13)+Chr(10)," ")
   cRetorno:=StrTran(cRetorno,"<i>","")
   cRetorno:=StrTran(cRetorno,"</i>","")
   cRetorno:=StrTran(cRetorno,"i-","i")
   cRetorno:=StrTran(cRetorno,"I-","I")
   cRetorno:=StrTran(cRetorno,"'"," ")

   For i := 1 To Len(cRetorno)
      If Upper(Subs(cRetorno,i,1)) $ cCarac
         cRet += Subs(cRetorno,i,1)
      Else
         cRet += " "
      EndIf
   Next

EndIf

Return cRet
