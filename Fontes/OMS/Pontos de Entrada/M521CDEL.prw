/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
       Autor      |    Data    |                                             Motivo                                           
-------------------------------------------------------------------------------------------------------------------------------
 Alexandre Villar | 07/11/2014 | Remoção do Controle de Expedição criado na implantação e não efetivado. Chamado 6863
-------------------------------------------------------------------------------------------------------------------------------
 Alexandre Villar | 13/08/2015 | Ajuste nas mensagems para facilitar o endentimento com relação aos títulos/documentos que não
                  |            | passarem nas validações. Chamado 11352
-------------------------------------------------------------------------------------------------------------------------------
 Lucas Borges     | 11/10/2019 | Removidos os Warning na compilação da release 12.1.25. Chamado 28346
===============================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "Rwmake.ch"
#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: M521CDEL
Autor-----------: Tiago Correa Castro
Data da Criacao-: 09/02/2009
===============================================================================================================================
Descrição-------: Ponto de Entrada na validacao da exclusao da nota de Saida. Valida se o titulo a Pagar do Autonomo ja foi 
					baixado nao permitindo assim a exclusao do Faturamento
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function M521CDEL()

Local lRet		:= .T.
Local _aInfHlp	:= {}
Local aArea		:= FWGetArea()
Local cCarga	:= SF2->F2_CARGA
Local dDtEmis	:= SF2->F2_EMISSAO     
   
//================================================================================
//| Verifica se a dataBase é valida para realizar a exclusao do documento        |
//================================================================================
If dDataBase < dDtEmis

	//================================================================================
	//| Cadastra o Help e Exibe                                                      |
	//================================================================================
	_aInfHlp := {}
	//                  |....:....|....:....|....:....|....:....|	  |....:....|....:....|....:....|....:....|	  |....:....|....:....|....:....|....:....|
	aAdd( _aInfHlp	, { 'Não é permitido estornar um documento '	, 'em data anterior à data de emissão. A '	, 'emissão do registro é:' + DToC(dDtEmis)	} )
	aAdd( _aInfHlp	, { 'Para excluir o documento atual deve '		, 'ser utilizada a (database) posterior à '	, 'data de emissão.'						} )
	
	U_ITCADHLP( _aInfHlp , "M521CD1" )
	
	Return( .F. )

EndIf

//================================================================================
//| Salvando Integridade do Sistema.                                             |
//================================================================================
DBSelectArea("SF2")
_nOrdSF2 := IndexOrd()
_nRecSF2 := Recno()

DBSelectArea("SD2")
_nOrdSD2 := IndexOrd()
_nRecSD2 := Recno()

//================================================================================
//| Tratativas exclusivas para o estorno de documentos de faturamento de carga   |
//================================================================================
If !Empty(cCarga)

	//================================================================================
	//| Verifica a chamada da função                                                 |
	//================================================================================
	If Upper( AllTrim( FunName() ) ) == "MATA521B"
	
		DBSelectArea("ZZ2")
		ZZ2->( DBSetOrder(2) ) // ZZ2_FILIAL+ZZ2_CARGA
		If ZZ2->( DBSeek( xFilial("ZZ2") + cCarga ) ) //Transporte realizado por Autonomo
		
			DBSelectArea("SE2")
			SE2->( DBSetOrder(1) ) //E2_FILIAL+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO+E2_FORNECE+E2_LOJA
			If SE2->( DBSeek( xFilial("SE2") + "AUT" + ZZ2->ZZ2_RECIBO ) )
				
				While SE2->( !Eof() ) .And. SE2->( E2_FILIAL + E2_PREFIXO + E2_NUM ) == xFilial("SE2") + "AUT" + ZZ2->ZZ2_RECIBO .And. AllTrim(SE2->E2_ORIGEM) == "GERAZZ3"
					
					//====================================================================================================
					// Verifica se houveram movimentações no título financeiro
					//====================================================================================================
					If SE2->E2_TIPO == "RPA" .And. SE2->E2_SALDO <> SE2->E2_VALOR
		
						MessageBox(	'O Título ['+ SE2->( E2_FILIAL+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO ) +'] possui baixas/movimentações e não pode ser excluído! '	+;
									'É necessário solicitar o estorno de todos os movimentos do título para prosseguir com o processo!' , 'Atenção!' , 48 )
						

						lRet := .F.
						
					EndIf
					
				SE2->( DBSkip() )
				EndDo
			
			EndIf
			
		EndIf
		
	Else
		
		//================================================================================
		//| Cadastra o Help e Exibe                                                      |
		//================================================================================
		_aInfHlp := {}
		//                  |....:....|....:....|....:....|....:....|	   |....:....|....:....|....:....|....:....|	  |....:....|....:....|....:....|....:....|
		aAdd( _aInfHlp	, { 'Não é permitido estornar um documento '	, 'gerado por Carga através da rotina atual!'	, ' Carga: ['+ cCarga +']'					} )
		aAdd( _aInfHlp	, { 'Para estorno desse documento deve ser '	, 'utilizada a rotina de Exclusão por Carga.'	, ''										} )
		
		U_ITCADHLP( _aInfHlp , "M521CD3" )
		
		lRet := .F.
		
	EndIf
	
EndIf

DBSelectArea("SD2")
DBSetOrder(_nOrdSD2)
DBGoTo(_nRecSD2)

DBSelectArea("SF2")
DBSetOrder(_nOrdSF2)
DBGoTo(_nRecSF2)

FWRestArea(aArea)

Return( lRet )
