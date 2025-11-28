/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |05/11/2024| Chamado 48795. Tratamento para o novo parâmetro IT_NAGEND: TP Entrega = C5_I_AGEND $ P=Aguardando 
			  |			 | Agenda; R=Reagendar; N=Reagendar com Multa
Alex Wallauer |21/03/2025| Chamado 50197. Novo tratamento para cortes e desmembramentos de pedidos - IGNORAR: M->C5_I_BLSLD = "S"
Lucas Borges  |17/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: OM200QRY
Autor-------------: Jeane
Data da Criacao---: 05/08/2009
Descrição---------: Ponto de entrada na inicialização da montagem de carga para filtrar os Pedidos
Parametros--------: Padrão ParamIXBXB ) - Contém a query que fará o filtro para ser complementada
Retorno-----------: _cFiltro - Query que será utilizada para filtrar os pedidos
===============================================================================================================================
*/
Static _lPerOM200QRY := .T.//Esse ponto de entrada é chamado 2 vezes seguidas no OMSA200, PQ a SELECT principal tem UNION portando devolve o mesmo filtro para as 2 SELECTs do UNION

User Function OM200QRY()
Local _cPerg   := "OM200QRY"
Local _cFiltro := ParamIXB[1]
Local nQdePerg	  := 40
Local aPergOld	  := {}, nLoop
Local _cIT_NAGEND := SuperGetMV("IT_NAGEND",.F., "P;R;N")//P=Aguardando Agenda; R=Reagendar; N=Reagendar 

// 01) "Estado"		     ,"C",99,0,"G","LSTEST","MV_PAR01"
// 02) "Municipio"       ,"C",99,0,"G","LSTMU2","MV_PAR02"
// 03) "Vendedor"        ,"C",99,0,"G","LSTVEN","MV_PAR03"
// 04) "Supervisor"	     ,"C",99,0,"G","LSTSUP","MV_PAR04"
// 05) "Rede"	         ,"C",99,0,"G","LSTRED","MV_PAR05"
// 06) "Peso de ?"       ,"N",12,4,"G","      ","MV_PAR06"
// 07) "Peso ate ?"      ,"N",12,4,"G","      ","MV_PAR07"
// 08) "Tipo de Carga ?" ,"N",01,0,"C","      ","MV_PAR08","Paletizada", "Batida","Ambas"
// 09) "Tipo de Agenda ?","C",15,0,"G","LSTTPA","MV_PAR09"
//=========================================
//Salva as perguntas originais da rotina
//=========================================

For nLoop := 1 To nQdePerg
	aAdd( aPergOld, &( "MV_PAR" + StrZero( nLoop, 2 ) ) )
Next

//====================================================================================================
// Caso as perguntas sejam canceladas Processa sem os filtros
//====================================================================================================
If Pergunte( _cPerg , _lPerOM200QRY) .Or. !_lPerOM200QRY// COLOQUEI "!_lPerOM200QRY" pq o pergunte(,.F.) com .F. devolve falso
	// Filtra Estado Cliente
	If !Empty( MV_PAR01 )
		_cFiltro += " AND SC5.C5_I_EST IN " + FormatIn( AllTrim( MV_PAR01 ) , ";" )
	EndIf

	If !Empty( _cIT_NAGEND )
		_cFiltro += " AND SC5.C5_I_AGEND NOT IN " + FormatIn( AllTrim( _cIT_NAGEND ) , ";" )
	EndIf
	
	//================================================================================
	// Filtra Cod Municipio Cliente
	//================================================================================
	If !Empty( MV_PAR02 )
		_cFiltro += " AND SC5.C5_I_CMUN IN " + FormatIn( AllTrim( MV_PAR02 ) , ";" )
	EndIf
	
	//================================================================================
	// Filtra vendedor
	//================================================================================
	If !Empty( MV_PAR03 )
		_cFiltro += " AND SC5.C5_VEND1 IN " + FormatIn( AllTrim( MV_PAR03 ) , ";" )
	EndIf
	
	//================================================================================
	// Filtra Supervisor
	//================================================================================
	If !Empty( MV_PAR04 )
		_cFiltro += " AND SC5.C5_VEND2 IN " + FormatIn( AllTrim( MV_PAR04 ) , ";" )
	EndIf
	
	//================================================================================
 	// Filtra Rede Cliente
	//================================================================================
	If !Empty( MV_PAR05 )
		_cFiltro += " AND SC5.C5_I_GRPVE IN " + FormatIn( AllTrim( MV_PAR05) , ";" )
	EndIf

	//================================================================================
	// Filtra Peso Bruto
	//================================================================================
	If MV_PAR06 > 0 .Or. MV_PAR07 > 0
		_cFiltro += " AND SC5.C5_I_PESBR BETWEEN " + AllTrim(Str(MV_PAR06)) + " AND " + AllTrim(Str(MV_PAR07)) + " "
	EndIf

	//================================================================================
	// Filtra Tipo de Carga
	//================================================================================
	If MV_PAR08 <> 3
		_cFiltro += " AND ( SC5.C5_I_TIPCA = '" + AllTrim(Str(MV_PAR08)) + "' OR SC5.C5_I_TIPCA = '')"
	EndIf

	//================================================================================
	// Filtra Tipo de Agendamento.
	//================================================================================
	If !Empty(MV_PAR09) // MV_PAR09 <> 5
	   //_cFiltro += " AND ( SC5.C5_I_AGEND = '" + AllTrim(Str(MV_PAR09)) + "' OR SC5.C5_I_AGEND = '')"
	   _cFiltro += " AND SC5.C5_I_AGEND IN " + FormatIn( AllTrim( MV_PAR09 ) , ";" )
	EndIf


EndIf

//=====================================================================================================================================//
// AWF - Projeto de unificação de pedidos de troca nota - Chamado 16548      
// Filtra Pedidos: - cujo preço informado estão fora da tabela de preços praticada pela empresa;
//                 - A liberação de preço está vencida ou ocorreu mudança nos preços do pedido
//                 - O cliente do pedido foi alterado desde a liberação de preço
//                 - Bloqueado por liberação completa de crédito expirada
//                 - Bloqueado por valor de liberação completa excedido
//                 - bonificação bloqueado
//                 - bonificação rejeitado
//                 - Avaliação de crédito do pedido não foi aprovada
//                 - Trazer somente os pedidos que nao tema carga automatica gerada
//=====================================================================================================================================//

_cFiltro += " AND ( "
_cFiltro += " ( SC5.C5_I_BLCRE = 'L' OR SC5.C5_I_BLCRE = '' )"//Credito
_cFiltro += " AND  (SC5.C5_I_BLPRC ='L' OR  SC5.C5_I_BLPRC ='')"//Preco
_cFiltro += " AND  (SC5.C5_I_BLOQ = 'L' OR SC5.C5_I_BLOQ = '')"//Bonificacao
_cFiltro += " ) "
_cFiltro += " AND ( SC5.C5_I_CARGA = '' )"//Trazer somente os pedidos que nao tema carga automatica gerada

// Filtra Pedidos Liberados Parcialmente
_cFiltro += " AND NOT EXISTS ( "
_cFiltro +=                    " SELECT "
_cFiltro +=                    "    SC6L.C6_ITEM "
_cFiltro +=                    " FROM "+ RetSqlName('SC6') +" SC6L "
_cFiltro +=                    " WHERE "
_cFiltro +=                    "     SC6L.D_E_L_E_T_ = ' ' "
_cFiltro +=                    " AND SC6L.C6_FILIAL  = SC9.C9_FILIAL "
_cFiltro +=                    " AND SC6L.C6_NUM     = SC9.C9_PEDIDO "
_cFiltro +=                    " AND NOT EXISTS ( SELECT SC9L.C9_PEDIDO FROM "+ RetSqlName('SC9') +" SC9L "
_cFiltro +=                    "                  WHERE SC9L.D_E_L_E_T_ = ' ' "
_cFiltro +=                    "                  AND   SC9L.C9_FILIAL  = SC6L.C6_FILIAL "
_cFiltro +=                    "                  AND   SC9L.C9_PEDIDO  = SC6L.C6_NUM "
_cFiltro +=                    "                  AND   SC9L.C9_ITEM    = SC6L.C6_ITEM 
_cFiltro +=                    "                  AND   SC9L.C9_BLEST	= ' ' "
_cFiltro +=                    "                  AND   SC9L.C9_BLCRED  = ' ' ) "
_cFiltro += " ) "

//Validação usuárioxFilialxarmazém
//verifica se usuário tem registro de restrição de armazéns na filial
DBSelectArea("Z14")
Z14->( DBSetOrder(1) )
	
If Z14->( DBSeek( xFilial("Z14") + AllTrim(RetCodUsr()) + xFilial("SC9") ) ) 

	//se tem restrição filtra para aparecer tudo que não é PA ou que esteja dentro da lista de armazéns permitidos
	_cFiltro += " AND ( "
	_cFiltro += " (  SELECT "
	_cFiltro += "      B1_TIPO " 
	_cFiltro += "    FROM " + RetSqlName('SB1') + " SB1T "
	_cFiltro += "    WHERE "
	_cFiltro += "      SB1T.B1_COD = SC9.C9_PRODUTO 
	_cFiltro += "      AND SB1.B1_FILIAL = '" + xFilial("SB1") + "'"
	_cFiltro += "      AND ROWNUM = 1 "
	_cFiltro += "      AND SB1T.D_E_L_E_T_ = ' ') <> 'PA' " 
	_cFiltro += " OR SC9.C9_LOCAL IN (" + StrTran ( AllTrim(Z14->Z14_LOCAL) , ";" , ",")  + ")"
	_cFiltro += " ) "
	
	_cFiltro += " AND NOT EXISTS ( (  SELECT  C9_LOCAL  FROM " + RetSqlName('SC9') + " SC9T WHERE"
   	_cFiltro += "     SC9T.C9_FILIAL = SC9.C9_FILIAL"
   	_cFiltro += "     AND SC9T.C9_PEDIDO = SC9.C9_PEDIDO"
   	_cFiltro += "     AND ( SELECT B1_TIPO FROM " + RetSqlName('SB1') + " SB1T2 WHERE SB1T2.B1_FILIAL = ' ' 
   	_cFiltro += "               AND SB1T2.B1_COD = SC9T.C9_PRODUTO 
   	_cFiltro += "               AND SB1T2.D_E_L_E_T_ = ' ' AND ROWNUM =1) = 'PA'
  	_cFiltro += "     AND SC9T.C9_LOCAL NOT IN (" + StrTran ( AllTrim(Z14->Z14_LOCAL) , ";" , ",") + ")"
   	_cFiltro += "     and SC9T.D_E_L_E_T_ = ' ' ) )

EndIf


//=========================================== 
//Não mostra pedidos enviados para RDC
//=========================================== 
_cFiltro += " AND C5_I_ENVRD <> 'S' "

//=========================================== 
//Novo tratamento para cortes e desmembramentos de pedidos - IGNORAR: M->C5_I_BLSLD = "S"
//=========================================== 
If SC5->(FIELDPOS("C5_I_BLSLD")) > 0
   _cFiltro += " AND C5_I_BLSLD = 'N' "
EndIf


//=========================================== 
//Não mostra pedidos de de Faturamento do Triangular
//=========================================== 
_cOperTriangular:= AllTrim(SuperGetMV("IT_OPERTRI",.F.,"05,42"))// Tipos de operações da operação trigular
_cOperFat:= LEFT(_cOperTriangular,2)//05
_cFiltro += " AND C5_I_OPER <> '"+_cOperFat+"' "//05

//=========================================== 
// Restaura os parâmetros originais da rotina
//===========================================

For nLoop := 1 To nQdePerg
	&( "MV_PAR" + StrZero( nLoop, 2 ) )	:= aPergOld[ nLoop ]
Next nLoop

_lPerOM200QRY := !_lPerOM200QRY

Return( _cFiltro )

/*
===============================================================================================================================
Programa----------: LSTMU2                                 
Autor-------------: Jeane
Data da Criacao---: 05/08/2009
Descrição---------: Consulta para a pergunta de municípios
Parametros--------: _cPerg - Configuração das Perguntas
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function LSTMU2()

Local _nI			:= 0

Private nTam		:= 0
Private nMaxSelect	:= 0
Private aCat		:= {}
Private MvRet		:= AllTrim( ReadVar() )
Private MvPar		:= ""
Private cTitulo		:= ""
Private MvParDef	:= ""

// Tratamento para carregar variaveis da lista de opcoes já selecionadas
nTam		:= 5
nMaxSelect	:= 16 //16 * 6 = 96 (cod(5) +";") = 6
cTitulo		:= "Municipios"

CC2->( DBSetOrder(1) )
CC2->( DBSeek( xFilial("CC2") ) )
While CC2->(!Eof()) .And. CC2->CC2_FILIAL == xFilial("CC2")
	
	//================================================================================
	// Caso tenha informado o(s) estado(s) só adiciona municipios referentes
	//================================================================================
	If !Empty( MV_PAR01 )
	
    	If CC2->CC2_EST $ AllTrim( MV_PAR01 )
    	
    		MvParDef += AllTrim(CC2->CC2_CODMUN)
			aAdd( aCat , AllTrim( CC2->CC2_MUN ) )
			
    	EndIf
    	
	Else
	
		MvParDef += AllTrim( CC2->CC2_CODMUN )
		aAdd( aCat , AllTrim( CC2->CC2_MUN ) )
		
	EndIf
	
	CC2->( DBSkip() )
EndDo

If Len( AllTrim( &MvRet ) ) == 0

	MvPar  := PadR( AllTrim( StrTran( &MvRet , ";" , "" ) ) , Len(aCat) )
	&MvRet := PadR( AllTrim( StrTran( &MvRet , ";" , "" ) ) , Len(aCat) )

Else

	MvPar  := AllTrim( StrTran( &MvRet , ";" , "/" ) )

EndIf

//================================================================================
// Executa funcao que monta tela de opcoes
//================================================================================
If F_Opcoes( @MvPar , cTitulo , aCat , MvParDef , 12 , 49 , .F. , nTam , nMaxSelect )

   //================================================================================
   // Tratamento para separar retorno com barra ";"
   //================================================================================
   &MvRet := ""

   For _nI := 1 To Len( MvPar ) Step nTam

	   If !( SubStr( MvPar , _nI , 1 ) $ " |*" )
	   	  &MvRet += SubStr( MvPar , _nI , nTam ) + ";"
	   EndIf
	
   Next

//================================================================================
// Trata para tirar o ultimo caracter
//================================================================================
   &MvRet := SubStr( &MvRet , 1 , Len( &MvRet ) - 1 )

EndIf

Return(.T.)
