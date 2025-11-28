/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Talita        |17/07/2013| Chamado 3749. Alterada validação para inclusão da TES que era feita pelo parâmetro IT_VCADTES e agora
              |          | será feita no campo ZZL_VCADTE.
Alexandre V.  |02/10/2015| Chamado 9688. Ajustes para gravação do LOG de alterações e bloqueio da TES para liberação Fiscal,
              |          | Estoque e Pis/Cofins.
Lucas Borges  |03/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: MT080GRV
Autor-----------: Tiago Correa
Data da Criacao-: 20/08/2008
Descrição-------: P.E. após a gravação dos dados da TES
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function MT080GRV()

Local _aArea 	:= FWGetArea()
Local _aDadLog	:= {}
Local _nPosBlq	:= 0
Local _nI		:= 0

//====================================================================================================
// Verifica tratativas na operação de inclusão
//====================================================================================================
If Inclui
	If SF4->F4_MSBLQL <> '1'
		SF4->( RecLock( 'SF4' , .F. ) )
		SF4->F4_MSBLQL	:= '1'
		SF4->F4_I_BLFPE	:= 'NNN'
		SF4->( MSUnLock() )
	EndIf
	
	//====================================================================================================
	// Monta a estrutura para a gravação do Log de inclusão
	//====================================================================================================
	aAdd( _aDadLog , {	'F4_FILIAL'	, SF4->F4_FILIAL	, '' } )
	aAdd( _aDadLog , {	'F4_CODIGO'	, SF4->F4_CODIGO	, '' } )
	
	U_ITGrvLog( _aDadLog , 'SF4' , 1 , SF4->( F4_FILIAL + F4_CODIGO ) , 'I' , RetCodUsr() , Date() , Time() )
	
	MessageBox(	'A TES é incluída bloqueada e deverá ser solicitada a liberação pelos responsáveis das áreas Fiscal, PIS/COFINS e Estoque. ' , 'MT080GRV01' , 48 )
	
	//====================================================================================================
	// Chama a replicação da TES para todas as Filiais
	//====================================================================================================
	GeraSF4()
EndIf

//====================================================================================================
// Verifica tratativas na operação de alteração
//====================================================================================================
If Altera .And. Type('_aDadSF4') == 'A' .And. !Empty( _aDadSF4 )
	For _nI := 1 To Len(_aDadSF4)
		If _aDadSF4[_nI][02] <> &( 'SF4->'+_aDadSF4[_nI][01] )
			aAdd( _aDadLog , { _aDadSF4[_nI][01] , _aDadSF4[_nI][02] , &( 'SF4->'+_aDadSF4[_nI][01] ) } )
		EndIf
	Next _nI
	
	If !Empty( _aDadLog )
		U_ITGrvLog( _aDadLog , 'SF4' , 1 , SF4->( F4_FILIAL + F4_CODIGO ) , 'A' , RetCodUsr() , Date() , Time() )
		_nPosBlq := aScan( _aDadLog , {|x| Upper(AllTrim(x[01])) == 'F4_MSBLQL' } )
		
		If _nPosBlq > 0 .And. _aDadLog[_nPosBlq][03] == '1'
			SF4->( RecLock( 'SF4' , .F. ) )
			SF4->F4_MSBLQL	:= '1'
			SF4->F4_I_BLFPE	:= 'NNN'
			SF4->( MSUnLock() )
		
			MessageBox(	'As alterações realizadas bloqueiam o cadastro da TES e deverá ser solicitada a liberação pelos responsáveis das áreas Fiscal, PIS/COFINS e Estoque. ' , 'MT080GRV02' , 48 )
			U_ITListBox( 'Alterações no cadastro de TES:' , {'Campo','Conteúdo Orig.','Novo Conteúdo'} , _aDadLog , .F. , 1 )
		EndIf
	EndIf
EndIf

FWRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa--------: GeraSF4
Autor-----------: Tiago Correa
Data da Criacao-: 20/08/2008
Descrição-------: Rotina para replicar a TES para todas as Filiais
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function GeraSF4()

Local _cEmpCor	:= cEmpAnt
Local _cFilCor	:= cfilAnt

DBSelectArea("SM0")
SM0->( DBGoTop() )
While SM0->( !Eof() ) .And. _cEmpCor == SM0->M0_CODIGO
	If	_cFilCor <> AllTrim(SM0->M0_CODFIL)
		DBSelectArea("SF4")
		RecLock( "SF4" , .T. )
		
			F4_FILIAL	:=	AllTrim(SM0->M0_CODFIL)
			F4_CODIGO	:=	M->F4_CODIGO
			F4_TIPO		:=	M->F4_TIPO
			F4_ICM 		:=	M->F4_ICM
			F4_IPI 		:=	M->F4_IPI
			F4_CREDICM 	:=	M->F4_CREDICM
			F4_CREDIPI 	:=	M->F4_CREDIPI
			F4_DUPLIC 	:=	M->F4_DUPLIC
			F4_ESTOQUE 	:=	M->F4_ESTOQUE
			F4_CF 		:=	M->F4_CF
			F4_TEXTO 	:=	AllTrim(M->F4_TEXTO)
			F4_PODER3 	:=	M->F4_PODER3
			F4_LFICM  	:=	M->F4_LFICM
			F4_LFIPI  	:=	M->F4_LFIPI
			F4_DESTACA  :=	M->F4_DESTACA
			F4_INCIDE  	:=	M->F4_INCIDE
			F4_COMPL 	:=	M->F4_COMPL
			F4_I_GTES  	:=	M->F4_I_GTES
			F4_FINALID	:=	M->F4_FINALID
			F4_MSBLQL	:=	"1"
			F4_I_BLFPE	:=	"NNN"
			
		MSUnLock()
	
	EndIf

	SM0->( DBSkip() )
EndDo

Return
