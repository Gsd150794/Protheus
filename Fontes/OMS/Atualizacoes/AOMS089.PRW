/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
       Autor      |    Data    |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
 Alex Wallauer    | 25/09/2017 | Volta do código de segurança para não zerar o numero do PV - Chamado 21574
 Josué Danich     | 20/12/2018 | Universalização da rotina - Chamado 27443 
======================================================================================================================================================================================================
 Analista    - Programador   - Inicio   - Envio    - Chamado - Motivo da Alteração
======================================================================================================================================================================================================
 Jerry       - Alex WALLAUER - 30/01/25 - 05/08/25 - 37652   - Ajuste para poder melhorar a mensagem de processamento.
 Jerry       - Igor Melgaço  - 07/08/25 - 07/08/25 - 51690   - Ajuste para correção de Error.log ao tentar criar a area STT.
 Jerry       - Alex WALLAUER - 21/08/25 - 21/08/25 - 51800   - Voltamos a versão para antes do dia 30/1/25 e colocamos um If para fechar o alias STT antes de abrir
 Jerry       - Julio Paz     - 04/09/25 - 10/09/25 - 51807   - Substituição da função DBUSEAREA() pela função MPSysOpenQuery(). Revisão da rotina.
======================================================================================================================================================================================================
*/
#Include "TOTVS.ch"
/*
===============================================================================================================================
Programa----------: AOMS089
Autor-------------: Josué Danich Prestes
Data da Criacao---: 13/12/2016
===============================================================================================================================
Descrição---------: Rotina de segurança para atualizar hardlock  - Chamado 18103
===============================================================================================================================
Parametros--------: _lauto - Rodando de schedule?
					     _alias - alias
					     _campo - campo
					     _lshow - mostra mensagens
					     _cfilial - filial do numerador
===============================================================================================================================
Retorno-----------: _cNum -> próximo número de pedido de vendas
===============================================================================================================================
*/
Static _lAtuSC5 := .F.
Static _cNumSC5 := ""
*===========================================================================*
User Function AOMS089(_lauto,_alias,_campo,_lshow,_cfilial)
*===========================================================================*
Local _cQuery  := ""
Local _aArea   := FWGetArea()
Private _cNum  := ""

Default _alias   := "SC5"
Default _campo   := "C5_NUM"
Default _lshow   := .T.
Default _cfilial := "99"

If ValType(_lauto) <> "L"
   _lauto := .T.
EndIf

If _lauto

   U_ITConout("******* \\\\\///// Inicio da Verificação do Numerador do "+ _alias + " Via Schedule: "+TIME()+" \\\\\/////*******")

   //Monta ambiente
   RPCSetType(3)
   RpcSetEnv( "01" , "01" ,,,"OMS", "AOMS089" , {_alias} )
   Sleep( 5000 ) //Aguarda 5 segundos para subam as configurações do ambiente.
   If _cfilial == "99"
  	   _cfilial := "01"
   EndIf
Else
	_cfilial := cfilant
EndIf

_cQuery := " SELECT max(" + _campo + ") MAXIMO FROM "+RetSqlName(_alias) +" WHERE D_E_L_E_T_ = ' ' "

If _alias != "SC5"
	_cQuery += " AND " + _alias + "_FILIAL = '" + _cfilial + "'"
EndIf

If Select("STT") > 0
   STT->(DBCloseArea())	
EndIf

MPSysOpenQuery( _cQuery , "STT") //DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , "STT" , .T. , .F. )
	
DBSelectArea("STT")

If ! STT->(Eof())
   _lAtuSC5:= .T.
   _cNumSC5:= AllTrim(STT->MAXIMO)
   
   If _alias == "SC5"
   	_cNum   := GetSXENum(_alias,_campo,"  \DATA\"+RETSQLNAME("SC5"),24)//GetSXENum(_cAlias,_cCpo)
   Else
      _cNum   := GetSXENum(_alias,_campo)
   EndIf 

   If Len(AllTrim(_cNum)) = Len(AllTrim(STT->MAXIMO))
	   If _lauto .Or. !_lshow
	      AOMS089T(_lauto,_alias,_campo,_lshow)
	   Else
	      Processa( {|| AOMS089T(_lauto,_alias,_campo,_lshow)}, "Aguarde...","Atualizando hardlock...",.T.)
	   EndIf
   Else
      U_ITMsg("Numerador do Hardlock esta com o tamanho diferente do campo: " + _campo,"Tamanho do numerador",;
              "Tamanhos: "+Str(Len(AllTrim(_cNum)),1)+" # "+Str(Len(AllTrim(STT->MAXIMO)),1)+". Entrar em contato com area de TI.",1)
   EndIf
EndIf

STT->(DBCloseArea())	

FWRestArea(_aArea)

Return _cNum

/*
===============================================================================================================================
Programa----------: AOMS089P
Autor-------------: Josué Danich Prestes
Data da Criacao---: 13/12/2016
===============================================================================================================================
Descrição---------: Roda atualização de hardlock - Chamado
===============================================================================================================================
Parametros--------: _lauto - Se está rodando em schedule
					     _alias - alias
					     _campo - campo
					     _lshow - se mostra mensagens
===============================================================================================================================
Retorno-----------: nenhum
===============================================================================================================================
*/
Static Function AOMS089T(_lauto,_alias,_campo,_lshow)

Local _nquant := Val(AllTrim(STT->MAXIMO)) - Val(AllTrim(_cNum))

If !_lauto .And. _lshow

  ProcRegua(_nquant)

EndIf

U_ITConout("****** //// Inicio da Atualização do Numerador do " + _alias + ": "+TIME()+"  \\\\******")
U_ITConout("****** \\\\ Atualizando Hardlock - Registro Inicial: " + AllTrim(_cNum) + " de " + AllTrim(STT->MAXIMO)+" ////******")

While AllTrim(_cNum) <= AllTrim(STT->MAXIMO)
	
	If !_lauto .And. _lshow
	   IncProc("Atualizando Hardlock - Registro: " + AllTrim(_cNum) + " de " + AllTrim(STT->MAXIMO))
	EndIf

   Confirmsx8(.F.)
   If _alias == "SC5"
   	_cNum   := GetSXENum(_alias,_campo,"  \DATA\"+RETSQLNAME("SC5"),24)//GetSXENum(_cAlias,_cCpo)
   Else
      _cNum   := GetSXENum(_alias,_campo)
   EndIf 
		
EndDo

U_ITConout("****** //// Atualizando Hardlock - Registro Final: " + AllTrim(_cNum) + " de " + AllTrim(STT->MAXIMO)+"   \\\\******")
U_ITConout("****** \\\\ Final da Atualização do Numerador do " + _alias + ": "+TIME()+"   ////******")

_lAtuSC5 := .F.

Return 

