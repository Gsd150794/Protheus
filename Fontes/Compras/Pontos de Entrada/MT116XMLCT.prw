/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alexandre V.  |11/11/2015| Chamado 12721. Ajuste para verificar se encontra a NF de Origem para alterar a busca por tipo de fornecedor.
Lucas Borges  |03/10/2019| Removidos os Warning na compilação da release 12.1.25. Chamado 28346
Lucas Borges  |02/09/2020| Corrigido lock da SDS. Chamado 34024
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MT116XMLCT
Autor-------------: Alexandre Villar
Data da Criacao---: 05/02/2015
Descrição---------: Ponto de Entrada para validar os campos gravados do XML referente a CT-e
					Este Ponto de Entrada é utilizado na rotina de Importação de XML de nota fiscal eletrônica, referente a 
					conhecimento de transporte que disponibiliza o objeto XML para implementações diversas dos usuarios.
Parametros--------: oXML -> O -> XML a ser importado
					cNF -> C -> Numero do conhecimento
					cSerie -> C -> Numero do serie do conhecimento
					cForn -> C -> Codigo do Fornecedor
					cLoja -> C -> Codigo da Loja/Fornecedor
					cTipo -> C -> Tipo do conhecimento
					cOpc -> C -> PF - Produto Frete / PN - Produto Nota Original
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MT116XMLCT

Local _aArea	:= FWGetArea()
Local _cAlias	:= ""
Local _cCodPrd	:= 'C'
Local _l0800	:= .F.

//====================================================================================================
// Incluída a tratativa para identificar o Fornecedor correto de acordo com o "Grupo de Produtos" para
// os casos onde o Fornecedor possui mais de um cadastro no Sistema com o mesmo CNPJ.
// Quando o Grupo começar com '0800' preferencialmente gravar os Fornecedores da Classe 'C'
// Para os demais preferencialmente gravar os Fornecedores de Classe 'T'
// Qunado não For encontrado um cadastro correspondente à regra, não altera o Fornecedor identificado
// originalmente. Chamado 8695
//====================================================================================================
DBSelectArea('SDT')
SDT->( DBSetOrder(1) )
If SDT->(DBSeek(SDS->(DS_FILIAL+DS_CNPJ+DS_FORNEC+DS_LOJA+DS_DOC+DS_SERIE)))
	While SDT->(!Eof()) .And. SDT->(DT_FILIAL+DT_CNPJ+DT_FORNEC+DT_LOJA+DT_DOC+DT_SERIE) == SDS->(DS_FILIAL+DS_CNPJ+DS_FORNEC+DS_LOJA+DS_DOC+DS_SERIE)
		If SubStr( SDT->DT_COD , 1 , 4 ) == '0800'
			_l0800 := .T.
			Exit
		EndIf
		SDT->( DBSkip() )
	EndDo
	If !_l0800
		SDT->( DBGoTop() )
		SDT->( DBSeek(SDS->(DS_FILIAL+DS_CNPJ+DS_FORNEC+DS_LOJA+DS_DOC+DS_SERIE)))
	EndIf
	
	If SubStr( SDT->DT_COD , 1 , 4 ) == '0800' .And. !Empty( SDT->DT_NFORI )
		
		//====================================================================================================
		// Verifica se existe a NF de Origem para alterar o tipo de fornecedor a pesquisar
		//====================================================================================================
		DBSelectArea('SF1')
		SF1->( DBSetOrder(1) )
		If SF1->( DBSeek(SDT->(DT_FILIAL+DT_NFORI+DT_SERIORI)))
			While SF1->( !Eof() ) .And. SF1->(F1_FILIAL+F1_DOC+F1_SERIE) == SDT->(DT_FILIAL+DT_NFORI+DT_SERIORI)
				If SF1->F1_FORMUL == 'S'
					_cCodPrd := 'G'
					Exit
				EndIf
			SF1->( DBSkip() )
			EndDo
		EndIf
		
		DBSelectArea('SA2')
		SA2->( DBSetOrder(3) )
		If SA2->( DBSeek( xFilial('SA2') + SDT->DT_CNPJ ) ) 
			
			While SA2->( !Eof() ) .And. SA2->( A2_FILIAL + A2_CGC ) == xFilial('SA2') + SDT->DT_CNPJ
				
				If SubStr(SA2->A2_COD,1,1) == _cCodPrd .And. SA2->A2_MSBLQL != "1"
					
					//====================================================================================================
					// Procura todos os itens da nota para localizar e atualizar via recno
					//====================================================================================================
					_cAlias := GetNextAlias()
					BeginSql alias _cAlias
						SELECT R_E_C_N_O_
						  FROM %Table:SDT%
						 WHERE DT_DOC = %exp:SDS->DS_DOC%
						   AND DT_FILIAL = %exp:SDS->DS_FILIAL%
						   AND DT_SERIE = %exp:SDS->DS_SERIE%
						   AND DT_FORNEC = %exp:SDS->DS_FORNEC%
						   AND DT_LOJA = %exp:SDS->DS_LOJA%
						   AND D_E_L_E_T_ = ' '
					EndSql
					
					While !(_cAlias)->( Eof() ) 
					
						SDT->( DBGoTo( (_cAlias)->R_E_C_N_O_) )
						
						RecLock( 'SDT' , .F. )
						SDT->DT_FORNEC := SA2->A2_COD
						SDT->DT_LOJA   := SA2->A2_LOJA
						SDT->( MSUnLock() )
						
						(_cAlias)->( DBSkip() )
					EndDo
		            
		 			(_cAlias)->(DBCloseArea())
		   			
					//====================================================================================================
					// Atualiza cabeçaho
					//====================================================================================================
					RecLock( 'SDT' , .F. )
					SDS->DS_FORNEC := SA2->A2_COD
					SDS->DS_LOJA   := SA2->A2_LOJA
					SDS->( MSUnLock() )
					
					Exit
					
				EndIf
				SA2->( DBSkip() )
			EndDo
		EndIf
	Else
		If SubStr( SDT->DT_FORNEC , 1 , 1 ) <> 'T'
			DBSelectArea('SA2')
			SA2->( DBSetOrder(3) )
			If SA2->( DBSeek( xFilial('SA2') + SDT->DT_CNPJ ) ) 
				While SA2->( !Eof() ) .And. SA2->( A2_FILIAL + A2_CGC ) == xFilial('SA2') + SDT->DT_CNPJ
					If SubStr( SA2->A2_COD , 1 , 1 ) == 'T' .And. SA2->A2_MSBLQL != "1"
						
						//====================================================================================================
		   				// Procura todos os itens da nota para localizar e atualizar via recno
		   				//====================================================================================================
						_cAlias := GetNextAlias()
						BeginSql alias _cAlias
							SELECT R_E_C_N_O_
							  FROM %Table:SDT%
							 WHERE DT_DOC = %exp:SDS->DS_DOC%
							   AND DT_FILIAL = %exp:SDS->DS_FILIAL%
							   AND DT_SERIE = %exp:SDS->DS_SERIE%
							   AND DT_FORNEC = %exp:SDS->DS_FORNEC%
							   AND DT_LOJA = %exp:SDS->DS_LOJA%
							   AND D_E_L_E_T_ = ' '
						EndSql
						
						While (_cAlias)->( !Eof() )
						
							SDT->( DBGoTo( (_cAlias)->R_E_C_N_O_ ) )
							
							RecLock( 'SDT' , .F. )
							SDT->DT_FORNEC	:= SA2->A2_COD
							SDT->DT_LOJA	:= SA2->A2_LOJA
							SDT->( MSUnLock() )
							
							(_cAlias)->( DBSkip() )
						EndDo
			            
			 			(_cAlias)->(DBCloseArea())
						
						//====================================================================================================
	          			// Atualiza cabeçalho
	          			//====================================================================================================
						RecLock( 'SDS' , .F. )
						SDS->DS_FORNEC := SA2->A2_COD
						SDS->DS_LOJA   := SA2->A2_LOJA
						SDS->( MSUnLock() )
						
						Exit
						
					EndIf
					SA2->( DBSkip() )
				EndDo
			EndIf
		EndIf
	EndIf
EndIf

FWRestArea( _aArea )

Return
