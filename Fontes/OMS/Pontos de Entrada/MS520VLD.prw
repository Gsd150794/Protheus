/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |08/12/2022| Chamado 41604. Novo tratamento para Pedidos de Operacao Triangular. 
Alex Wallauer |09/01/2023| Chamado 41604. Correcao de erro de digitacao em mensagem na tela. 
Lucas Borges  |17/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
-==============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MS520VLD
Autor-------------: Tiago Correa Castro
Data da Criacao---: 15/12/2008
Descrição---------: Ponto de Entrada no momento da exclusao da Nota Fiscal de Saida (SF2)
Parametros--------: Nenhum
Retorno-----------: .T. - Permite o estorno
------------------: .F. - Impede o estorno
===============================================================================================================================
*/
User Function MS520VLD(_lSair)

Local _aArea	:= FWGetArea()
Local _lRet		:= .T. 
Default _lSair  := .F.
_lUsuConfirmou  := .T.//Se passou por aqui é que o Usario Confirmou o Estorno variavel usada no rdmake M520BROW.PRW nao retirar
//==============================================================================//
// AWF-Alex Wallauer - 28/09/2016 - Chamado 16548
// Projeto de unificação de pedidos de troca nota - Chamado 16548
// Funcao para verificar: 
// Se a nota de transferência já foi recepcionada na filial de Faturamento
//==============================================================================//
If _lRet
   _lRet := IT_Ver_TN()
   If _lSair
      Return _lRet
   EndIf
EndIf

//==============================================================================//
// AWF-Alex Wallauer - 17/06/2016 - Chamado 14489                                   
// Funcao para verificar: 
//  Se a nota For uma nota de transferência e já foi incluída como documento 
//  de entrada na filial de destino.
//==============================================================================//
If _lRet
   _lRet := IT_Ver_NFT()
EndIf

//==============================================================================//
// AWF-Alex Wallauer - 17/06/2016 - Chamado 14489                                   
// Funcao para verificar: 
//  Se o tempo decorrido desde o envio da NFe para o 
//  Sefaz For maior que a quantidade de horas indicada no parâmetro MV_SPEDEXC
//==============================================================================//
If _lRet
   _lRet := IT_Ver_Prazo()
EndIf

//================================================================================
//| Funcao para verificar se existem titulos ST e se nao houveram baixas         |
//================================================================================
If _lRet .And. SF2->F2_TIPO = "N"
	_lRet := IT_Ver_ST()
EndIf

//================================================================================
//| Chama a função responsavel por verificar se algum titulo possui baixa        | - 06/02/13 - Talita
//================================================================================
If _lRet
	_lRet := IT_Ver_NCC()
EndIf

//================================================================================
//| Verifica incidência de Impostos Posteriores, não permite alteração retroativa| - 25/07/14 - Alexandre Villar
//================================================================================
If _lRet
	_lRet := IT_Ver_IMP()
EndIf

FWRestArea( _aArea )

//================================================================================
//Verifica uso de armazéns restritos para usuárioxFilial
//================================================================================
If _lRet
	_lRet := IT_Ver_ARM()
EndIf

//================================================================================
//Verifica o Pedido de Faturamento de Operacao Triangular // DEIXE ESSE SEMPRE POR ULTIMO PQ ELE EXECUTA UMA EXCLUSAO 
//================================================================================
If _lRet
	_lRet := IT_Ver_OT()// DEIXE ESSE SEMPRE POR ULTIMO PQ ELE EXECUTA UMA EXCLUSAO 
EndIf


FWRestArea( _aArea )

Return( _lRet )

/*
===============================================================================================================================
Programa----------: IT_Ver_ST
Autor-------------: Guilherme Gesualdo
Data da Criacao---: 10/09/2012
Descrição---------: Funcao usada para verificar se existe titulos ST para a nota, e se houver verifica se houve baixas.
Parametros--------: Nenhum
Retorno-----------: .T. - Permite o estorno
------------------: .F. - Impede o estorno
===============================================================================================================================
*/
Static Function IT_Ver_ST()

Local _aArea	:= FWGetArea()

Local _cFilial	:= SF2->F2_FILIAL
Local _cSerie	:= SF2->F2_SERIE
Local _cDoc		:= SF2->F2_DOC
Local _cCodCli	:= SF2->F2_CLIENTE
Local _cLojCli	:= SF2->F2_LOJA
Local _cFORST	:= AllTrim(SuperGetMV("IT_STFORN",.F.,""))
Local _nE1IcmV	:= 0
Local _nE1IcmS	:= 0
Local _nE2IcmV	:= 0
Local _nE2IcmS	:= 0
Local lRet		:= .T.

DBSelectArea("SE1")
SE1->( DBSetOrder(2) ) //E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO

If SE1->( DBSeek( _cFilial + _cCodCli + _cLojCli + _cSerie + _cDoc + Space(2) + 'ICM' ) )

	_nE1IcmV := SE1->E1_VALOR
    _nE1IcmS := SE1->E1_SALDO
    
EndIf

//Salva valor e saldo do titulo a pagar ICM
DBSelectArea("SE2")
SE2->( DBSetOrder(1) ) //E2_FILIAL+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO+E2_FORNECE+E2_LOJA

If DBSeek(xFilial("SE2")+_cSerie+_cDoc+Space(2)+'ICM'+SubStr(_cFORST,1,6)+SubStr(_cFORST,7,4))

	_nE2IcmV := SE2->E2_VALOR
	_nE2IcmS := SE2->E2_SALDO 
	
EndIf 

If _nE1IcmV == _nE1IcmS .And. _nE2IcmV == _nE2IcmS  

	lRet     := .T.
	
Else

	xMagHelpFis(	"TITULO(S) COM BAIXA(S) (MS520VLD)"																								,;
					"Não será possível realizar a exclusão do documento pois o mesmo tem título(s) de ST Antecipado com baixa(s)."			,;
		            "Favor exclua a(s) baixa(s) do(s) título(s) e tente novamente a exclusão do documento. Dados do(s) título(s):"+ CRLF	+;
		            "PREFIXO: "+AllTrim(_cSerie)+", TIPO: ICM, NUMERO: " + _cDoc															 )
	
   	lRet := .F.
   	
EndIf
	
FWRestArea( _aArea )

Return(lRet)

/*
===============================================================================================================================
Programa----------: IT_Ver_NCC
Autor-------------: Talita
Data da Criacao---: 06/06/2013
Descrição---------: Funcao usada para verificar se existe titulos NCC para a nota, e se houver verifica se houve baixas.
Parametros--------: Nenhum
Retorno-----------: .T. - Permite o estorno
------------------: .F. - Impede o estorno
===============================================================================================================================
*/
Static Function IT_Ver_NCC()

Local _aArea	:= FWGetArea()
Local _cFilial	:= SF2->F2_FILIAL
Local _cSerie	:= "DCT"
Local _cDoc		:= SF2->F2_DOC
Local _cCodCli	:= SF2->F2_CLIENTE
Local _cLojCli	:= SF2->F2_LOJA
Local _nE1NccV	:= 0
Local _nE1NccS	:= 0
Local _lRet		:= .T.

DBSelectArea("SE1")
SE1->( DBSetOrder(2) ) //E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
If SE1->( DBSeek( _cFilial + _cCodCli + _cLojCli + _cSerie + _cDoc ) )

	While SE1->( !Eof() ) .And. SE1->E1_NUM = _cDoc .And. _nE1NccV = _nE1NccS
	
		If SE1->E1_TIPO = "NCC"
		
			_nE1NccV := SE1->E1_VALOR
		    _nE1NccS := SE1->E1_SALDO
	    	
		EndIf
		
	SE1->( DBSkip() )
	EndDo
	
	If _nE1NccV == _nE1NccS
	
		_lRet     := .T.
		
	Else
	
		_lRet := .F.
		
		xMagHelpFis(	"TITULO(S) COM BAIXA(S) (MS520VLD)"																								,;
						"Não será possível realizar a exclusão do documento pois o mesmo tem título(s) de NCC com baixa(s)."					,;
		                "Favor exclua a(s) baixa(s) do(s) título(s) e tente novamente a exclusão do documento. Dados do(s) título(s):"+ CRLF	+;
		                "PREFIXO: "+AllTrim(_cSerie)+", TIPO: NCC, NUMERO: "+ _cDoc																 )
	EndIf

EndIf

FWRestArea(_aArea)

Return( _lRet )

/*
===============================================================================================================================
Programa----------: IT_Ver_IMP
Autor-------------: Alexandre Villar
Data da Criacao---: 15/12/2008
Descrição---------: Valida se houveram faturamentos posteriores com retenção de impostos
Parametros--------: Nenhum
Retorno-----------: .T. - Permite o estorno
------------------: .F. - Impede o estorno
===============================================================================================================================
*/
Static Function IT_Ver_IMP()

Local _lRet		:= .T.
Local _aInfHlp	:= {}
Local _aRegPos	:= {}
Local _aCabec	:= {}
Local _aRegZZ2	:= {}
Local _cMsgAux	:= ''
Local _cAlias	:= GetNextAlias()
Local _cCodAut	:= ""
Local _cRegZZ2	:= ""
Local _cRegSF2	:= ""
Local _cQuery	:= ""

If !Empty( SF2->F2_CARGA )

	DBSelectArea('ZZ2')
	ZZ2->( DBSetOrder(2) )
	If ZZ2->( DBSeek( SF2->( F2_FILIAL + F2_CARGA ) ) )
		
		_cCodAut	:= ZZ2->ZZ2_AUTONO
		_cNumRPA	:= ZZ2->ZZ2_RECIBO
		_cNumCar	:= ZZ2->ZZ2_CARGA
		_cRegZZ2	:= cValToChar( ZZ2->( Recno() ) )
		_cRegSF2	:= U_ITSF2REG()//cValToChar( SF2->( Recno() ) )
		_cRegSE2	:= U_ITSE2REG()
		_cDtRef		:= SubStr( DToS( SF2->F2_EMISSAO ) , 1 , 6 )
		
		If ZZ2->ZZ2_INSS > 0 .Or. ZZ2->ZZ2_IRRF > 0
			
			//================================================================================
			//| Verifica caso o RPA atual tenha imposto se existem registros posteriores     |
			//================================================================================
			_cQuery += " SELECT DISTINCT "
			_cQuery += " 	'1'				AS TIPO		,"
			_cQuery += " 	ZZ2.R_E_C_N_O_	AS REGZZ2	,"
			_cQuery += "	SE2.R_E_C_N_O_	AS REGAUX	 "
			_cQuery += " FROM "+ RetSqlName('ZZ2') +" ZZ2 "
			_cQuery += " INNER JOIN "+ RetSqlName('SE2') +" SE2 ON "
			_cQuery += " 		SE2.E2_FILIAL				= ZZ2.ZZ2_FILIAL "
			_cQuery += " AND	SE2.E2_NUM					= ZZ2.ZZ2_RECIBO "
			_cQuery += " AND	SE2.E2_NUM					<> '"+ _cNumRPA +"' "
			_cQuery += " AND	SE2.E2_PREFIXO				= 'AUT' "
			_cQuery += " AND	SE2.E2_ORIGEM				IN ( 'AOMS042' , 'MGLT011' , 'GERAZZ3' ) "
			_cQuery += " AND	SubStr(SE2.E2_EMISSAO,1,6)	= '"+ _cDtRef	+"' "
			_cQuery += " AND	SE2.R_E_C_N_O_				> '"+ _cRegSE2 +"' "
			_cQuery += " AND	SE2.D_E_L_E_T_				= ' ' "
			_cQuery += " WHERE "
			_cQuery += " 		ZZ2.ZZ2_AUTONO				= '"+ _cCodAut	+"' "
			_cQuery += " AND	SubStr(ZZ2.ZZ2_DATA,1,6)	= '"+ _cDtRef	+"' "
			_cQuery += " AND	ZZ2.ZZ2_CARGA				= ' ' "
			_cQuery += " AND	ZZ2.D_E_L_E_T_				= ' ' "
			
			_cQuery += " UNION ALL "
			
			_cQuery += " SELECT DISTINCT "
			_cQuery += " 	'2'				AS TIPO		,"
			_cQuery += " 	ZZ2.R_E_C_N_O_	AS REGZZ2	,"
			_cQuery += "	SF2.R_E_C_N_O_	AS REGAUX	 "
			_cQuery += " FROM "+ RetSqlName('ZZ2') +" ZZ2 "
			_cQuery += " INNER JOIN "+ RetSqlName('SF2') +" SF2 ON "
			_cQuery += " 		SF2.F2_FILIAL				= ZZ2.ZZ2_FILIAL "
			_cQuery += " AND	SF2.F2_CARGA				= ZZ2.ZZ2_CARGA "
			_cQuery += " AND	SF2.F2_CARGA				<> '"+ _cNumCar +"' "
			_cQuery += " AND	SubStr(SF2.F2_EMISSAO,1,6)	= '"+ _cDtRef +"' "
			_cQuery += " AND	SF2.R_E_C_N_O_				> '"+ _cRegSF2 +"' "
			_cQuery += " AND	SF2.D_E_L_E_T_				= ' ' "
			_cQuery += " WHERE "
			_cQuery += " 		ZZ2.ZZ2_AUTONO	= '"+ _cCodAut	+"' "
			_cQuery += " AND	SubStr(ZZ2.ZZ2_DATA,1,6)	= '"+ _cDtRef	+"' "
			_cQuery += " AND	ZZ2.ZZ2_CARGA	<> ' ' "
			_cQuery += " AND	ZZ2.D_E_L_E_T_	= ' ' "
		Else
			//================================================================================
			//| Verifica RPA com impostos no mesmo período após o atual sem impostos         |
			//================================================================================
			_cQuery += " SELECT DISTINCT "
			_cQuery += " 	'1'				AS TIPO		,"
			_cQuery += " 	ZZ2.R_E_C_N_O_	AS REGZZ2	,"
			_cQuery += "	SE2.R_E_C_N_O_	AS REGAUX	 "
			_cQuery += " FROM "+ RetSqlName('ZZ2') +" ZZ2 "
			_cQuery += " INNER JOIN "+ RetSqlName('SE2') +" SE2 ON "
			_cQuery += " 		SE2.E2_FILIAL				= ZZ2.ZZ2_FILIAL "
			_cQuery += " AND	SE2.E2_NUM					= ZZ2.ZZ2_RECIBO "
			_cQuery += " AND	SE2.E2_NUM					<> '"+ _cNumRPA +"' "
			_cQuery += " AND	SE2.E2_PREFIXO				= 'AUT' "
			_cQuery += " AND	SE2.E2_ORIGEM				IN ( 'AOMS042' , 'MGLT011' , 'GERAZZ3' ) "
			_cQuery += " AND	SubStr(SE2.E2_EMISSAO,1,6)	= '"+ _cDtRef	+"' "
			_cQuery += " AND	SE2.R_E_C_N_O_				> '"+ _cRegSE2 +"' "
			_cQuery += " AND	SE2.D_E_L_E_T_				= ' ' "
			_cQuery += " WHERE "
			_cQuery += " 		ZZ2.ZZ2_AUTONO				= '"+ _cCodAut	+"' "
			_cQuery += " AND	SubStr(ZZ2.ZZ2_DATA,1,6)	= '"+ _cDtRef	+"' "
			_cQuery += " AND	ZZ2.ZZ2_CARGA				= ' ' "
			_cQuery += " AND (	ZZ2.ZZ2_INSS				> 0 "
			_cQuery += "     OR	ZZ2.ZZ2_IRRF				> 0 ) "
			_cQuery += " AND	ZZ2.D_E_L_E_T_				= ' ' "
			
			_cQuery += " UNION ALL "
			
			_cQuery += " SELECT DISTINCT "
			_cQuery += " 	'2'				AS TIPO		,"
			_cQuery += " 	ZZ2.R_E_C_N_O_	AS REGZZ2	,"
			_cQuery += "	SF2.R_E_C_N_O_	AS REGAUX	 "
			_cQuery += " FROM "+ RetSqlName('ZZ2') +" ZZ2 "
			_cQuery += " INNER JOIN "+ RetSqlName('SF2') +" SF2 ON "
			_cQuery += " 		SF2.F2_FILIAL				= ZZ2.ZZ2_FILIAL "
			_cQuery += " AND	SF2.F2_CARGA				= ZZ2.ZZ2_CARGA "
			_cQuery += " AND	SF2.F2_CARGA				<> '"+ _cNumCar +"' "
			_cQuery += " AND	SubStr(SF2.F2_EMISSAO,1,6)	= '"+ _cDtRef +"' "
			_cQuery += " AND	SF2.R_E_C_N_O_				> '"+ _cRegSF2 +"' "
			_cQuery += " AND	SF2.D_E_L_E_T_				= ' ' "
			_cQuery += " WHERE "
			_cQuery += " 		ZZ2.ZZ2_AUTONO				= '"+ _cCodAut	+"' "
			_cQuery += " AND	ZZ2.ZZ2_CARGA				<> ' ' "
			_cQuery += " AND ( ZZ2.ZZ2_INSS					> 0 "
			_cQuery += "   OR  ZZ2.ZZ2_IRRF					> 0 ) "
			_cQuery += " AND	ZZ2.D_E_L_E_T_				= ' ' "
			
		EndIf
		
		If Select(_cAlias) > 0
			(_cAlias)->( DBCloseArea() )
		EndIf
		
		DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , _cAlias , .T. , .F. )
		
		DBSelectArea(_cAlias)
		(_cAlias)->( DBGoTop() )
		While (_cAlias)->( !Eof() )
			
			If (_cAlias)->TIPO == '1'
				
				If aScan( _aRegZZ2 , (_cAlias)->REGZZ2 ) == 0
				
					DBSelectArea('ZZ2')
					ZZ2->( DBGoTo( (_cAlias)->REGZZ2 ) )
					
					aAdd( _aRegPos , {	'RPA Avulso'		,; //Tipo
										ZZ2->ZZ2_FILIAL		,; //Filial
										''					,; //Número da Carga
										ZZ2->ZZ2_RECIBO		,; //Número do RPA/Nota
										ZZ2->ZZ2_DATA		,; //Data de Emissão
										ZZ2->ZZ2_TOTAL		,; //Valor Total
										ZZ2->( Recno() )	}) //Recno
					
					aAdd( _aRegZZ2 , (_cAlias)->REGZZ2 )
				
				EndIf
				
			Else
			    
				DBSelectArea('ZZ2')
				ZZ2->( DBGoTo( (_cAlias)->REGZZ2 ) )
				
				DBSelectArea('SF2')
				SF2->( DBGoTo( (_cAlias)->REGAUX ) )
				
				aAdd( _aRegPos , {	'Carga'							,; //Tipo
									ZZ2->ZZ2_FILIAL					,; //Filial
									ZZ2->ZZ2_CARGA					,; //Número de Carga
									SF2->F2_DOC +'/'+ SF2->F2_SERIE	,; //Número do RPA/Nota
									SF2->F2_EMISSAO					,; //Data de Emissão
									SF2->F2_VALBRUT					,; //Valor Total
									SF2->( Recno() )				}) //Recno
				
			EndIf
			
		(_cAlias)->( DBSkip() )
		EndDo
		
		If !Empty(_aRegPos)
			
			_lRet		:= .F.
			_aRegPos	:= MS520VLDORD( _aRegPos )
			
			//                  |....:....|....:....|....:....|....:....|	  |....:....|....:....|....:....|....:....|	  |....:....|....:....|....:....|....:....|
			aAdd( _aInfHlp	, { "Não é possível estornar Notas que foram "	, "consideradas nos cálculos de impostos e ", "que possuem movimentação posterior. "	} )
			aAdd( _aInfHlp	, { "Verifique os dados da NF a estornar! "		, "(MS520VLD)"								, ""										} )
			
			//===========================================================================
			//| Cadastra o Help e Exibe                                                 |
			//===========================================================================
			U_ITCADHLP( _aInfHlp , "M520VL1" )
			
			//===========================================================================
			//| Exibe a lista de registros posteriores para conferência                 |
			//===========================================================================
			_aCabec		:= { 'Tipo' , 'Filial' , 'Carga' , 'Documento' , 'Emissão' , 'Valor Total' }
			_cMsgAux	:= '['+ StrZero( Len( _aRegPos ) , 3 ) +'] lançamentos posteriores:
			U_ITListBox( 'Lançamentos posteriores encontrados (MS520VLD)' , _aCabec , _aRegPos , .T. , 1 , _cMsgAux )
			
			//================================================================================
			//| Verifica se o usuario tem permissao para executar o Estorno sem validar      | - 31/07/14 - Alexandre Villar
			//================================================================================
			DBSelectArea("ZZL")
			ZZL->( DBSetOrder(3) )
			If ZZL->( DBSeek( xFilial("ZZL") + RetCodUsr() ) )
			
				If ZZL->ZZL_ECARGA == "S"
				
					If Aviso( 'Atenção!' , 'O estorno do documento atual não passou pela validação de impostos, deseja prosseguir com o estorno mesmo assim?' , {'Estornar','Cancelar'} ) == 1
						_lRet := .T.
					EndIf
				EndIf
			EndIf
		EndIf
	EndIf
EndIf

Return( _lRet )

/*
===============================================================================================================================
Programa----------: ITSE2REG
Autor-------------: Alexandre Villar
Data da Criacao---: 29/07/2014
Descrição---------: Retorna o Recno do SE2 de acordo com o posicionamento no SF2
Parametros--------: Nenhum
Retorno-----------: .T. - Permite o estorno
------------------: .F. - Impede o estorno
===============================================================================================================================
*/
User Function ITSE2REG()

Local _cQuery	:= ''
Local _cAlias	:= GetNextAlias()
Local _cRet		:= ''

_cQuery := " SELECT R_E_C_N_O_ AS REGSE2 "
_cQuery += " FROM "+ RetSqlName('SE2') +" SE2 "
_cQuery += " WHERE "
_cQuery += " 		SE2.E2_FILIAL	= '"+ ZZ2->ZZ2_FILIAL +"' "
_cQuery += " AND	SE2.E2_PREFIXO	= 'AUT' "
_cQuery += " AND	SE2.E2_NUM		= '"+ ZZ2->ZZ2_RECIBO +"' "
_cQuery += " AND	SE2.E2_ORIGEM	IN ( 'AOMS042' , 'MGLT011' , 'GERAZZ3' ) "
_cQuery += " AND	SE2.D_E_L_E_T_	= ' ' "

If Select(_cAlias) > 0
	(_cAlias)->( DBCloseArea() )
EndIf
        
DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , _cAlias , .T. , .F. )

DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )
If (_cAlias)->( !Eof() )
	_cRet := cValToChar( (_cAlias)->REGSE2 )
EndIf

Return( _cRet )

/*
===============================================================================================================================
Programa----------: ITSF2REG
Autor-------------: Alexandre Villar
Data da Criacao---: 29/07/2014
Descrição---------: Retorna o Recno do SE2 de acordo com o posicionamento no SF2
Parametros--------: Nenhum
Retorno-----------: .T. - Permite o estorno
------------------: .F. - Impede o estorno
===============================================================================================================================
 */
User Function ITSF2REG()

Local _cQuery	:= ''
Local _cAlias	:= GetNextAlias()
Local _cRet		:= ''

_cQuery := " SELECT MAX( R_E_C_N_O_ ) AS REGSF2 "
_cQuery += " FROM "+ RetSqlName('SF2') +" SF2 "
_cQuery += " WHERE "
_cQuery += " 		SF2.F2_FILIAL	= '"+ ZZ2->ZZ2_FILIAL	+"' "
_cQuery += " AND	SF2.F2_CARGA	= '"+ ZZ2->ZZ2_CARGA	+"' "
_cQuery += " AND	SF2.D_E_L_E_T_	= ' ' "

If Select(_cAlias) > 0
	(_cAlias)->( DBCloseArea() )
EndIf
        
DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , _cAlias , .T. , .F. )

DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )
If (_cAlias)->( !Eof() )
	_cRet := cValToChar( (_cAlias)->REGSF2 )
EndIf

Return( _cRet )

/*
===============================================================================================================================
Programa----------: MS520VLDORD
Autor-------------: Alexandre Villar
Data da Criacao---: 07/08/2014
Descrição---------: Ordena os registros de acordo com o Recno da SE2 gerados para o RPA
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MS520VLDORD( _aRegPos )

Local _aArea	:= FWGetArea()
Local _aAux		:= {}
Local _aRet		:= {}
Local _cAlias	:= GetNextAlias()
Local _cQuery	:= ''
Local _nI		:= 0

For _nI := 1 To Len( _aRegPos )
	
	_cQuery := " SELECT MAX(SE2.R_E_C_N_O_) AS REGSE2 "
	_cQuery += " FROM "+ RetSqlName('SE2') +" SE2 "
	_cQuery += " WHERE "
	
	If Empty( _aRegPos[_nI][03] )
		
		DBSelectArea('ZZ2')
		ZZ2->( DBGoTo( _aRegPos[_nI][07] ) )
		
	Else
		
		DBSelectArea('SF2')
		SF2->( DBGoTo( _aRegPos[_nI][07] ) )
		
		DBSelectArea('ZZ2')
		ZZ2->( DBSetOrder(2) )
		If !ZZ2->( DBSeek( SF2->( F2_FILIAL + F2_CARGA ) ) )
			Loop
		EndIf
		
	EndIf
	
	_cQuery += " 		SE2.E2_FILIAL				= '"+ ZZ2->ZZ2_FILIAL +"' "
	_cQuery += " AND	SE2.E2_NUM					= '"+ ZZ2->ZZ2_RECIBO +"' "
	_cQuery += " AND	SE2.E2_PREFIXO				= 'AUT' "
	_cQuery += " AND	SE2.E2_ORIGEM				IN ( 'AOMS042' , 'MGLT011' , 'GERAZZ3' ) "
	_cQuery += " AND	SubStr(SE2.E2_EMISSAO,1,6)	= '"+ SubStr( DToS(ZZ2->ZZ2_DATA) , 1 , 6 ) +"' "
	_cQuery += " AND	SE2.D_E_L_E_T_				= ' ' "
	
	If Select(_cAlias) > 0
		(_cAlias)->( DBCloseArea() )
	EndIf
	
	DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , _cAlias , .T. , .F. )
	
	DBSelectArea(_cAlias)
	(_cAlias)->( DBGoTop() )
	If (_cAlias)->(!Eof())
		
		aAdd( _aAux , {	(_cAlias)->REGSE2	,;
						_aRegPos[_nI][01]	,;
						_aRegPos[_nI][02]	,;
						_aRegPos[_nI][03]	,;
						_aRegPos[_nI][04]	,;
						_aRegPos[_nI][05]	,;
						_aRegPos[_nI][06]	})
		
	EndIf
	
Next _nI

If !Empty(_aAux)

	_aAux := aSort( _aAux ,,, {|x, y| x[1] < y[1] } )
	
	For _nI := 1 To Len(_aAux)
		
		aAdd( _aRet , {	_aAux[_nI][02]	,;
						_aAux[_nI][03]	,;
						_aAux[_nI][04]	,;
						_aAux[_nI][05]	,;
						_aAux[_nI][06]	,;
						_aAux[_nI][07]	})
		
	Next _nI
	
EndIf

FWRestArea( _aArea )

Return( _aRet )

/*
===============================================================================================================================
Programa----------: IT_Ver_Arm
Autor-------------: Josué Danich Prestes
Data da Criacao---: 05/10/2015
Descrição---------: Valida se nota excluida não usa armazens restritos para o usuarioxFilial
Parametros--------: Nenhum
Retorno-----------: .T. - Permite o estorno
------------------: .F. - Impede o estorno
===============================================================================================================================
*/
Static Function IT_Ver_arm()

Local _aArea	:= FWGetArea()

Local _cFilial	:= SF2->F2_FILIAL
Local _cDoc		:= SF2->F2_DOC
Local _cCodCli	:= SF2->F2_CLIENTE
Local _cLojCli	:= SF2->F2_LOJA
Local _cSerie		:= SF2->F2_SERIE
Local _cmens		:= ""
Local _aRet		:= {}
Local _cCodUsr	:= AllTrim(RetCodUsr())
Local _lRet		:= .T.

DBSelectArea("SD2")
SD2->( DBSetOrder(3) ) //D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA

If SD2->( DBSeek( _cFilial + _cDoc +  _cSerie + _cCodCli + _cLojCli ) )

	While SD2->( !Eof() ) .And. SD2->D2_FILIAL == _cFilial .And. SD2->D2_DOC == _cDoc .And. SD2->D2_SERIE == _cSerie .And. SD2->D2_CLIENTE == _cCodCli;
								.And. SD2->D2_LOJA == _cLojCli 
	
		_aRet:= U_ACFG004E(_cCodUsr, AllTrim(xFilial("SD2")), AllTrim(SD2->D2_LOCAL),AllTrim(SD2->D2_COD),.F.)
		
		//se ainda está valido verifica se não teve erro
		If _lRet
		
		  	_lRet:= _aRet[1]
		
		EndIf
		
		// adiciona armazens com problema se ainda não estiver na mensagem
		If Empty(_cmens)
		
			_cmens += "Nota: " + AllTrim(SD2->D2_DOC) + "/" + AllTrim(SD2->D2_SERIE) + " e armazém: " + _aRet[2]
			
		ElseIf !(_aRet[2]$_cmens) .And. !(Empty(_aRet[2])) 
		
			_cmens += ",  " + CRLF + "Nota: " + AllTrim(SD2->D2_DOC) + "/" + AllTrim(SD2->D2_SERIE) + " e armazém: " + _aRet[2]
			
		EndIf
		
		SD2->( DBSkip() )
	
	EndDo
	
	If .not. _lRet .And. .not. Empty(_cmens)
	
		xMagHelpFis(	"Armazéns restritos (MS520VLD)"																								,;
						"Não será possível realizar a exclusão do documento pois o mesmo usa os armazéns abaixo restritos ao usuário e filial atual:"	 + CRLF;
						+CRLF + _cmens, "Caso necessário solicite a manutenção à um usuário com acesso ou, se necessário, solicite o acesso à área de TI/ERP.")															 
	EndIf

EndIf

FWRestArea(_aArea)

Return( _lRet )

/*
===============================================================================================================================
Programa----------: IT_Ver_Prazo
Autor-------------: Alex Wallauer
Data da Criacao---: 17/06/2016
Descrição---------: Funcao para verificar se o tempo decorrido desde o envio da NFe para o Sefaz For maior que a quantidade de
					 horas indicada no parâmetro MV_SPEDEXC
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: .T. - Permite o estorno
------------------: .F. - Impede o estorno
===============================================================================================================================
*/
Static Function IT_Ver_Prazo()

Local _aArea	:= FWGetArea()
Local cAlias    := GetNextAlias()  
Local _ChaveID	:= SF2->F2_CHVNFE
Local _nPrazo 	:= GETMV("MV_SPEDEXC")
Local _lRet		:= .T.
Local cDataA    :=""
Local cTimeA    :=""
Local nHorasDIf :=0
Local cDataS    :=""
Local cTimeS    :=""

If Empty(_ChaveID)
   Return .T.
EndIf

BeginSql Alias cAlias  
			
	SELECT ID_ENT, DATE_NFE, TIME_NFE FROM SPED050 WHERE D_E_L_E_T_ = ' ' AND DOC_CHV = %Exp:_ChaveID%

EndSql    	 	

If Empty( (cAlias)->DATE_NFE ) .Or. Empty( (cAlias)->TIME_NFE )
   (cAlias)->(DBCloseArea())
   Return .T.
EndIf

cDataA:=Date()
cTimeA:=LEFT(Time(),5)
cDataS:=SToD((cAlias)->DATE_NFE)
cTimeS:=LEFT((cAlias)->TIME_NFE,5)

nHorasDIf := SubtHoras( cDataS, cTimeS, cDataA, cTimeA )

cDataA:=DToC(Date())
cTimeA:=Time()
cDataS:=DToC(SToD((cAlias)->DATE_NFE))
cTimeS:=(cAlias)->TIME_NFE

If nHorasDIf > _nPrazo
	
   _lRet := .F.
		
   xMagHelpFis("PRAZO DE CANCELAMENTO DA SEFAZ (MS520VLD)",;
			   "Não será possível realizar a exclusão do documento pois o prazo para cancelamento da NFE no Sefaz expirou.",;
               "Nota / Serie: "+SF2->F2_DOC+" / "+SF2->F2_SERIE + CRLF+;
               "Prazo de cancelamento da SEFAZ: "+AllTrim(Str(_nPrazo,10))+" horas"+CRLF+;
               "Data / Hora da Geracao da SEFAZ: "+cDataS+" - "+cTimeS+ CRLF+;
               "Data / Hora Atual: "+cDataA+" - "+cTimeA+ CRLF+;
               "Diferenca de horas: "+AllTrim(TRANS(nHorasDif,"@E 999,999,999.99"))+" horas"+ CRLF	+;
               "")
EndIf

(cAlias)->(DBCloseArea())

FWRestArea(_aArea)

Return( _lRet )

/*
===============================================================================================================================
Programa----------: IT_Ver_NFT
Autor-------------: Alex Wallauer
Data da Criacao---: 17/06/2016
Descrição---------: Funcao para verificar: 
//Se a nota For uma nota de transferência e já foi incluída como documento de entrada na filial de destino
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: .T. - Permite o estorno
------------------: .F. - Impede o estorno
===============================================================================================================================
*/
Static Function IT_Ver_NFT()

Local cAlias    := GetNextAlias()  
Local _aArea	:= FWGetArea()
Local _cFilNT   := ""
Local _cCGC     := ""
Local _cNotaT   := SF2->F2_DOC
Local _cSerieT  := SF2->F2_SERIE
Local _cFornT   := ""
Local _cLojaT   := ""
Local _lRet		:= .T.

SA1->(DBSetOrder(1))
If SA1->(DBSeek(xFilial()+SF2->F2_CLIENTE+SF2->F2_LOJA))
   _cCGC:=SA1->A1_CGC
EndIf

If Empty(_cCGC)
   Return .T.
EndIf

BeginSql Alias cAlias  
			
	SELECT ZZM_CODIGO FROM ZZM010 WHERE D_E_L_E_T_ = ' ' AND ZZM_CGC = %Exp:_cCGC%

EndSql    	 	

_cFilNT := (cAlias)->ZZM_CODIGO

If Empty(_cFilNT)
   Return .T.
EndIf

ZZM->(DBSetOrder(1))
If ZZM->(DBSeek(xFilial()+SF2->F2_FILIAL))
   _cCGC:=ZZM->ZZM_CGC
EndIf

If Empty(_cCGC)
   Return .T.
EndIf

SA2->(DBSetOrder(3))
If SA2->(DBSeek(xFilial()+_cCGC))
   _cFornT := SA2->A2_COD
   _cLojaT := SA2->A2_LOJA
EndIf
SA2->(DBSetOrder(1))

If Empty(_cFornT)
   Return .T.
EndIf

SF1->(DBSetOrder(1))
If SF1->(DBSeek(_cFilNT+_cNotaT+_cSerieT+_cFornT+_cLojaT ))
	
   _lRet := .F.
		
   xMagHelpFis("NOTA DE TRANSFERENCIA (MS520VLD)",;
			   "Nota de transferência já foi recepcionada no destino.",;
               "Filial que recepcionou a N.T.: "+_cFilNT+CRLF+;
               "Nota / Serie: "+_cNotaT+" / "+ _cSerieT+CRLF+;
               "Fornecedor / Loja da N.T.: "+_cFornT +" / "+_cLojaT+CRLF+;
               "Entre em contato com departamento fiscal.")
EndIf

FWRestArea(_aArea)

Return( _lRet )

/*
===============================================================================================================================
Programa----------: IT_Ver_TN 
Autor-------------: Alex Wallauer
Data da Criacao---: 28/09/2016
Descrição---------: Projeto de unificação de pedidos de troca nota - Chamado 16548
Para verificar----: Se a nota For uma nota de transferência e já foi incluída como documento de entrada na filial de destino
Parametros--------: Nenhum
Retorno-----------: .T. - Permite o estorno
------------------: .F. - Impede o estorno
===============================================================================================================================
*/
Static Function IT_Ver_TN()

Local _aArea	:= FWGetArea()
Local _cCGC     := ""
Local _cNotaT   := SF2->F2_DOC
Local _cSerieT  := SF2->F2_SERIE
Local _cFornT   := ""
Local _cLojaT   := ""
Local _lRet		:= .T.
Local _lPed_Troca_NF  :=.F.
Local _cFilFaturamento:= ""
Local _lEstou_na_Fil_Faturamento:= .F.

SC5->( DBSetOrder(1) )
If SC5->(DBSeek(xFilial()+SF2->F2_I_PEDID))
   _lPed_Troca_NF  :=(SC5->C5_I_TRCNF = "S")
   _cFilFaturamento:= SC5->C5_I_FILFT
   _lEstou_na_Fil_Faturamento:= (SC5->C5_I_FILFT = SC5->C5_FILIAL)
EndIf

If !_lPed_Troca_NF .Or. _lEstou_na_Fil_Faturamento .Or. Empty(_cFilFaturamento)
   Return .T.
EndIf  

ZZM->(DBSetOrder(1))
If ZZM->(DBSeek(xFilial()+SF2->F2_FILIAL))//Filial de carregamento
   _cCGC:=ZZM->ZZM_CGC
EndIf

If Empty(_cCGC)
   Return .T.
EndIf

SA2->(DBSetOrder(3))
If SA2->(DBSeek(xFilial()+_cCGC))
   _cFornT := SA2->A2_COD
   _cLojaT := SA2->A2_LOJA
EndIf
SA2->(DBSetOrder(1))

If Empty(_cFornT)
   Return .T.
EndIf

SF1->(DBSetOrder(1))
If SF1->(DBSeek(_cFilFaturamento+_cNotaT+_cSerieT+_cFornT+_cLojaT ))
	
   _lRet := .F.
		
   xMagHelpFis("PEDIDO DE TROCA NOTA (MS520VLD)",;
			   "Nota de transferência já foi recepcionada no destino.",;
               "Filial que recepcionou a N.T.: "+_cFilFaturamento+CRLF+;
               "Nota / Serie: "+_cNotaT+" / "+ _cSerieT+CRLF+;
               "Fornecedor / Loja da N.T.: "+_cFornT +" / "+_cLojaT+CRLF+;
               "Entre em contato com departamento fiscal.")
EndIf

FWRestArea(_aArea)

Return( _lRet )

/*
===============================================================================================================================
Programa----------: IT_Ver_OT
Autor-------------: Alex Wallauer
Data da Criacao---: 16/12/2022
Descrição---------: Projeto Novo tratamento para Pedidos de Operacao Triangular - Chamado 41604
Para verificar----: Se o pedido de faturamento da Operacao Triangular (operacao: 05) já gerou nota 
Parametros--------: Nenhum
Retorno-----------: .T. - Permite o estorno
------------------: .F. - Impede o estorno
===============================================================================================================================
*/
Static Function IT_Ver_OT()

Local _lRet		:= .T. , nInc
Local _cOperTriangular:=AllTrim(SuperGetMV("IT_OPERTRI",.F.,"05,42"))// Tipos de operações da operação trigular
Local _cOperRemessa:=RIGHT(_cOperTriangular,2)

If Type("_lNotaCarga") = "L" .And. !_lNotaCarga//EXCLUI QUANDO NÃO É POR CARGA

   If SC5->C5_I_OPER = _cOperRemessa 
      DBSelectArea("SC5") 
      For nInc := 1 To SC5->(FCount())
      	  M->&(SC5->(FieldName(nInc))) := SC5->(FieldGet(nInc))
      Next
	  _lDeuErro:=.F.
      Processa( {|| _lDeuErro:=U_IT_OperTriangular(SC5->C5_NUM,.T.) } ,, "Excluindo Pedido de Operação Triangular..." )
	  _lRet:=!_lDeuErro
   EndIf

ElseIf Type("_lNotaCarga") = "L" .And. _lNotaCarga//VALIDA QUANDO É POR CARGA
   
   If SC5->C5_I_OPER = _cOperRemessa 
      M->C5_I_PVFAT:=SC5->C5_I_PVFAT
	  If SC5->(DBSeek(xFilial()+M->C5_I_PVFAT))
	     If !Empty(SC5->C5_NOTA)

            _lRet := .F.
         		
            xMagHelpFis("PEDIDO FATURAMENTO TRIANGULAR (MS520VLD)",;
         			   "Pedido de Faturamento da Operacao Triangular já FATURADO",;
                        "Filial Pedido de Faturamento: "+xFilial("SC5")+CRLF+;
                        "Pedido de Faturamento: "+M->C5_I_PVFAT+CRLF+;
                        "Nota Fiscal: "+SC5->C5_NOTA+CRLF+;
                        "Entre em contato com departamento fiscal.")

		 EndIf
	  EndIf
   
   EndIf
EndIf
	
Return( _lRet )
