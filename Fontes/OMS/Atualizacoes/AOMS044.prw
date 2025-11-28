/*
===============================================================================================================================
                                    ATUALIZACOES SOFRIDAS DESDE A CONSTRUÇAO INICIAL
===============================================================================================================================
       Autor      |    Data    |                                             Motivo                                           |
------------------:------------:----------------------------------------------------------------------------------------------:
 Alexandre Villar | 30/04/2015 | Ajuste para atualização do campo A3_I_MSBLQ para A3_MSBLQL. Chamado 8875                     |
------------------:------------:----------------------------------------------------------------------------------------------:
 Julio Paz        | 20/12/2021 | Ajustar as validações para validar, também, os campos A1_I_VEND3 e A1_I_VEND4.Chamado 38654. |
===============================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AOMS044
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 13/04/2010
===============================================================================================================================
Descrição---------: Validação do cadastro de Vendedores no Pedido de Vendas
===============================================================================================================================
Uso---------------: Italac - Permite ou não a operação de acordo com a situação do cadastro do Vendedor
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
Usuario-----------: 
===============================================================================================================================
Setor-------------: TI
===============================================================================================================================
*/

User Function AOMS044( _cCodVen , _nOpc )

Local _lRet     := .T.
Local _aArea    := FWGetArea()
Local _cVarAux	:= ''

Default _nOpc	:= 0

DBSelectArea('SA3')
SA3->( DBSetOrder(1) )
If SA3->( DBSeek( xFilial("SA3") + _cCodVen ) )

	If SA3->A3_I_TIPV == "V"

		//====================================================================================================
		// Indica que o vendedor esta bloqueado, e não permite realizar a operacao solicitada.
		//====================================================================================================
		If SA3->A3_MSBLQL == '1'
		
			_lRet := .F.    //|....:....|....:....|....:....|....:....|      |....:....|....:....|....:....|....:....|   |....:....|....:....|....:....|....:....|
			ShowHelpDlg(	'Atenção!' ,;
							{ 'O Vendedor informado não é válido para o '  , 'processamento pois o mesmo encontra-se ' , 'bloqueado no cadastro do Sistema!'	} ,;
							3 ,;
							{ 'Verifique o cadastro do vendedor ou '       , 'informe outro código para continuar.'												} ,;
							2 )
			
		EndIf
		
		If _lRet .And. _nOpc == 1
			
			_cVarAux := ReadVar()
			
			If Upper( AllTrim( _cVarAux ) ) == 'M->A1_VEND'
				
				If (!Empty( M->A1_I_VEND2 ) .And. M->A1_I_VEND2 == _cCodVen ) .Or. (!Empty( M->A1_I_VEND3 ) .And. M->A1_I_VEND3 == _cCodVen ) ;
				   .Or. (!Empty( M->A1_I_VEND4 ) .And. M->A1_I_VEND4 == _cCodVen )
					
					_lRet := .F.    //|....:....|....:....|....:....|....:....|      |....:....|....:....|....:....|....:....|
					ShowHelpDlg(	'Atenção!' ,;
									{ 'Não é possível utilizar o mesmo Vendedor '  , 'em mais de um cadastro para atendimento à um ' , 'mesmo Cliente!' } ,;
									3 ,;
									{ 'Verifique os Vendedores informados e caso ' , 'necessário informe outro Vendedor.'							} ,;
									2 )
					
				EndIf
				
			ElseIf Upper( AllTrim( _cVarAux ) ) == 'M->A1_I_VEND2'
				
				If (!Empty( M->A1_VEND ) .And. M->A1_VEND == _cCodVen) .Or. (!Empty( M->A1_I_VEND3 ) .And. M->A1_I_VEND3 == _cCodVen ) ;
				   .Or. (!Empty( M->A1_I_VEND4 ) .And. M->A1_I_VEND4 == _cCodVen )
					
					_lRet := .F.    //|....:....|....:....|....:....|....:....|      |....:....|....:....|....:....|....:....|
					ShowHelpDlg(	'Atenção!' ,;
									{ 'Não é possível utilizar o mesmo Vendedor '  , 'em mais de um cadastro para atendimento à um ' , 'mesmo Cliente!' } ,;
									3 ,;
									{ 'Verifique os Vendedores informados e caso ' , 'necessário informe outro Vendedor.'							} ,;
									2 )
					
				EndIf
			
			ElseIf Upper( AllTrim( _cVarAux ) ) == 'M->A1_I_VEND3'
				
				If !Empty( M->A1_VEND ) .And. M->A1_VEND == _cCodVen .Or. (!Empty( M->A1_I_VEND2 ) .And. M->A1_I_VEND2 == _cCodVen ) ;
				   .Or. (!Empty( M->A1_I_VEND4 ) .And. M->A1_I_VEND4 == _cCodVen )
					
					_lRet := .F.    //|....:....|....:....|....:....|....:....|      |....:....|....:....|....:....|....:....|
					ShowHelpDlg(	'Atenção!' ,;
									{ 'Não é possível utilizar o mesmo Vendedor '  , 'em mais de um cadastros para atendimento à um ' , 'mesmo Cliente!' } ,;
									3 ,;
									{ 'Verifique os Vendedores informados e caso ' , 'necessário informe outro Vendedor.'							} ,;
									2 )
					
				EndIf

            ElseIf Upper( AllTrim( _cVarAux ) ) == 'M->A1_I_VEND4'
				
				If (!Empty( M->A1_VEND ) .And. M->A1_VEND == _cCodVen) .Or. (!Empty( M->A1_I_VEND2 ) .And. M->A1_I_VEND2 == _cCodVen ) ;
				   .Or. (!Empty( M->A1_I_VEND3 ) .And. M->A1_I_VEND3 == _cCodVen ) 
					
					_lRet := .F.    //|....:....|....:....|....:....|....:....|      |....:....|....:....|....:....|....:....|
					ShowHelpDlg(	'Atenção!' ,;
									{ 'Não é possível utilizar o mesmo Vendedor '  , 'em mais de um cadastro para atendimento à um ' , 'mesmo Cliente!' } ,;
									3 ,;
									{ 'Verifique os Vendedores informados e caso ' , 'necessário informe outro Vendedor.'							} ,;
									2 )
					
				EndIf
				
			EndIf
			
		EndIf
	
	Else
		
		_lRet := .F.    //|....:....|....:....|....:....|....:....|      |....:....|....:....|....:....|....:....|
		ShowHelpDlg(	'Atenção!' ,;
						{ 'O código de Vendedor informado não está '   , 'classificado como Vendedor no Sistema! '	} ,;
						2 ,;
						{ 'Verifique o código informado e digite um '  , 'código de vendedor válido.'				} ,;
						2 )
		
	EndIf
	
//====================================================================================================
// Nao existe o vendedor cadastrado na tabela SA3 ou o código não é válido para Vendedor
//====================================================================================================
Else

	_lRet := .F.    //|....:....|....:....|....:....|....:....|      |....:....|....:....|....:....|....:....|
	ShowHelpDlg(	'Atenção!' ,;
					{ 'O código de "Vendedor" informado não foi '  , 'encontrado no cadastro do Sistema! '		} ,;
					2 ,;
					{ 'Verifique o código informado e digite um '  , 'código de vendedor válido.'				} ,;
					2 )

EndIf

FWRestArea( _aArea )

Return( _lRet )
