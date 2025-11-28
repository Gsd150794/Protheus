/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |14/08/2018| Chamado 25825. Alteracao da gravação do arquivo de LOG
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: EFDCON03
Autor-------------: Alex Wallauer
Data da Criacao---: 14/05/2018
Descrição---------: Ponto de entrada de ajuste de dados no Sped Pis/Cofins - Chamado 23254
Parametros--------: 
  ParamIXB[1] //SE1/SE2/SE3
  ParamIXB[2] //E1_NUM/E2_NUM/E5_NUMERO
  ParamIXB[3] //E1_PREFIXO/E2_PREFIXO/E5_PREFIXO
  ParamIXB[4] //E1_PARCELA/E2_PARCELA/E5_PARCELA
  ParamIXB[5] //E1_TIPO/E2_TIPO/E5_TIPO
  ParamIXB[6] //E1_CLIENTE/E2_FORNECE/E5_CLIENTE/E5_FORNECE
  ParamIXB[7] //E1_LOJA/E2_LOJA/E5_LOJA
  ParamIXB[8] //E1_NATUREZ/E2_NATUREZ/E2_NATUREZ
  ParamIXB[9] //SE1->R_E_C_N_O_/SE2->R_E_C_N_O_/SE5->R_E_C_N_O_
Retorno-----------: _cContAju - Código da Conta Contábil Ajustada
===============================================================================================================================
*/
User Function EFDCON03()

Local _cContAju    :=  Space(Len(ZGH->ZGH_CONTA)) //Se não tiver regra retorna vazio para não gerar a linha 500
Local _cTabela     :=  ParamIXB[1] //SE1/SE2/SE3
Local _cNaturez    :=  ParamIXB[8] //E1_NATUREZ/E2_NATUREZ/E2_NATUREZ
Local _nRecno      :=  ParamIXB[9] //SE1->R_E_C_N_O_/SE2->R_E_C_N_O_/SE5->R_E_C_N_O_
Local _cFilial     :=  xFilial("ZGH")

(_cTabela)->(DBGoTo(_nRecno))

If _cTabela = "SE1" 
   _cFilial:= SE1->E1_FILIAL
ElseIf _cTabela = "SE2"
   _cFilial:= SE2->E2_FILIAL
ElseIf _cTabela = "SE3"
   _cFilial:= SE3->E3_FILIAL
EndIf

ZGH->(DBSetOrder(4))//ZGH_FILIAL+ZGH_NATURE

If ZGH->(DBSeek(_cFilial+_cNaturez )) 
   _cContAju := ZGH->ZGH_CONTA
EndIf

If Empty(_cContAju)
	_cFileNome:="\DATA\ITALAC\CONTROLE\SPEED500N.CSV"
	nHandle:=0
	If FILE(_cFileNome)
		nHandle:=FOpen(_cFileNome,2)
	EndIf
	If nHandle > 0
       cString:=Space(10)
       FReadLn(nHandle,@cString, 10, .F.) 
       If Empty(cString)
		  _cLinha:="User;Filia;Natureza;Tabela;Recno"+CRLF
          FWrite(nHandle,_cLinha)
       EndIf
 	   _cLinha:=cUserName+";"+_cFilial+";"+_cNaturez+";"+_cTabela+";"+AllTrim(Str( _nRecno ))+CRLF
	   FSEEK(nHandle,0,2)
	   FWrite(nHandle,_cLinha)
	   FClose(nHandle)
  	   U_ITCONOUT(_cLinha)
	EndIf
EndIf	

Return _cContAju
