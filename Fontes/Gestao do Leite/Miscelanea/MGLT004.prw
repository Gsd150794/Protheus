/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alexandre V.  |22/12/2015| Chamado 13062. Tratativa na cláusula "ORDER BY" para remover a referência numérica.
Alex Wallauer |02/02/2018| Chamados 23351. Filtrar filiais que tem no SmartQuestion e Ajustes de tela para a versão 12.
Lucas Borges  |28/09/2018| Chamados 26404. Retirada validação do campo ZLU_DESPRO e transferida para o Privilégio. Rotina 
 			  |			 | reescrita e alterada de AGLT026 para MGLT004.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MGLT004
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 28/09/2018
Descrição---------: Rotina para Inativação de Produtores que não tiveram coleta de leite no período informado
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGLT004()

Private _cPerg		:= "MGLT004"
Private _oSelf		:= nil

//============================================
//Cria interface principal
//============================================
tNewProcess():New(	_cPerg											,; // Função inicial
					"Inativa Produtores"						,; // Descrição da Rotina
					{|_oSelf| MGLT004P(_oSelf) }				,; // Função do processamento
					"Rotina para efetuar a desativação dos produtores que não realizaram " +;
					"movimentação de entrada de Leite de acordo com os parâmetros informados." ,; // Descrição da Funcionalidade
					_cPerg											,; // Configuração dos Parâmetros
					{}												,; // Opções adicionais para o painel lateral
					.F.												,; // Define criação do Painel auxiliar
					0												,; // Tamanho do Painel Auxiliar
					''												,; // Descrição do Painel Auxiliar
					.T.												 ) // Opção para criação de apenas uma régua de processamento


Return

/*
===============================================================================================================================
Programa----------: MGLT004P
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 28/09/2018
Descrição---------: Realiza o processamento da rotina.
Parametros--------: _oSelf
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGLT004P(_oSelf)

Local _cFiltro		:= "%"
Local _cFiltroFilial:= SuperGetMV("LT_FILPROD", .F. ,"01,02,04,06,09,0A,0B,40,10,11,20,23,24,25") //filiais com integração com o SmartQuestion
Local _cAlias		:= GetNextAlias()
Local _nCountRec	:= 0
Local _nI,_nSQ		:= 0
Local _nProcessado	:= 0
Local _aLstFor		:= {}

_oSelf:SetRegua1(2)
_oSelf:IncRegua1("Buscando produtores...")
//====================================================================================================
// Monta filtro para os Setores informados
//====================================================================================================
_cFiltro  += " AND ZL3.ZL3_SETOR IN "+ FormatIn( AllTrim(MV_PAR03) , ';' )
_cFiltro  += "%"

//====================================================================================================
// SQL para verificar os produtores dos Setores que nao movimentaram entrada de leite no periodo
//====================================================================================================
BeginSql Alias _cAlias
SELECT A2.A2_COD, A2.A2_LOJA, A2.A2_NOME
  FROM %Table:SA2% A2, %Table:ZL3% ZL3
 WHERE A2.D_E_L_E_T_ = ' '
   AND ZL3.D_E_L_E_T_ = ' '
   AND A2.A2_FILIAL = %xFilial:SA2%
   AND A2.A2_L_LI_RO = ZL3.ZL3_COD
   AND A2.A2_COD LIKE 'P%'
   AND A2_L_ATIVO = 'S'
   %exp:_cFiltro%
   AND A2.A2_COD NOT IN
       (SELECT ZLD_RETIRO
          FROM %Table:ZLD% ZLD
         WHERE ZLD.D_E_L_E_T_ = ' '
           AND ZLD.ZLD_FILIAL = %xFilial:ZLD%
           AND ZLD_DTCOLE BETWEEN %exp:DToS(MV_PAR01)% AND %exp:DToS(MV_PAR02)%
           AND ZLD.ZLD_RETIRO = A2.A2_COD
           AND ZLD.ZLD_RETILJ = A2.A2_LOJA
        UNION ALL
        SELECT ZLW_RETIRO
          FROM %Table:ZLW% ZLW
         WHERE ZLW.D_E_L_E_T_ = ' '
           AND ZLW.ZLW_FILIAL = %xFilial:ZLW%
           AND ZLW_DTCOLE BETWEEN %exp:DToS(MV_PAR01)% AND %exp:DToS(MV_PAR02)%
           AND ZLW.ZLW_RETIRO = A2.A2_COD
           AND ZLW.ZLW_RETILJ = A2.A2_LOJA)
 ORDER BY A2.A2_COD, A2.A2_LOJA
EndSql

Count To _nCountRec
(_cAlias)->( DBGoTop() )
_oSelf:IncRegua1("Montando janela de seleção...")

//====================================================================================================
// Verifica os dados selecionados e exibe tela para seleção dos produtores
//====================================================================================================
If _nCountRec > 0
	While (_cAlias)->(!Eof())
		aAdd( _aLstFor , { .F. , (_cAlias)->A2_COD , (_cAlias)->A2_LOJA , (_cAlias)->A2_NOME } )
		(_cAlias)->( DBSkip() )
	EndDo
	(_cAlias)->( DBCloseArea() )
	
	DBSelectArea("SA2")
	SA2->( DBSetOrder(1) )
	//====================================================================================================
	// Exibe a tela e confirmação antes de processar a atualização de status
	//====================================================================================================
	While .T.
	
		If U_ITListBox(	"Desativação de Fornecedores inativos",{ "X" , "Código" , "Loja" , "Nome" } , @_aLstFor , .T. , 2 ,;
					AllTrim(Str(_nCountRec,9))+" registros encontrados no Período solicitado de "+ DToC(MV_PAR01) +" até "+ DToC(MV_PAR02)+" dos setores: "+AllTrim(MV_PAR03))
			If MsgYesNo("Confirma o processamento de desativação dos Fornecedores selecionados ?")
				_oSelf:SetRegua2(_nCountRec)
				_nProcessado:=0
				_nSQ:=0
				For _nI := 1 To Len(_aLstFor)
					_oSelf:IncRegua2("Processando a desativação ["+ StrZero(_nI,6) +"] de ["+ StrZero(Len(_aLstFor),6) +"]")
						If _aLstFor[_nI][01]
						setAtivo( _aLstFor[_nI][02] , _aLstFor[_nI][03] , _cFiltroFilial, @_nSQ )
						_nProcessado++
					EndIf
				Next _nI
				If _nProcessado = 0
					MsgStop("Nenhum produtor marcado Marque pelo menos um produtor.","MGLT00402")
					Loop
				Else
					MsgInfo("Foram inativados "+AllTrim(Str(_nProcessado))+" produtores com sucesso e "+AllTrim(Str(_nSQ))+" marcado(s) para envio para o SmartQuestion!","MGLT00403")
					Exit
				EndIf
			Else
				Loop
			EndIf
		Else
			Return(.F.)
		EndIf
		Exit
	EndDo

Else
	MsgAlert("Não foram encontrados registros para processar com os filtros informados! Verifique os parâmetros digitados.","MGLT00404")
	Return
EndIf

Return

/*
===============================================================================================================================
Programa----------: setAtivo
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 28/09/2018
Descrição---------: Inativa o produtor
Parametros--------: cpProd -> código que será inativado
------------------: cpLoja -> loja que será inativada
------------------: _cFiltroFilial -> filiais que possuem integração com SmartQuestion
------------------: _nSQ -> Contador de registros alterados para integração
Retorno-----------: _nSQ -> Incrementa o contador
===============================================================================================================================
*/
Static Function setAtivo( cpProd , cpLoja , _cFiltroFilial, _nSQ )

SA2->( DBSeek( xFilial("SA2") + cpProd + cpLoja ) )

SA2->( RecLock( "SA2" , .F. ) )
SA2->A2_L_ATIVO	:= 'N'
SA2->A2_L_DTDES	:= SubStr( DToS(MV_PAR01) , 5 , 2 ) + SubStr( DToS( MV_PAR02 ) , 1 , 4 )
If SubStr( SA2->A2_L_LI_RO,1,2) $ _cFiltroFilial
	_nSQ++
	SA2->A2_L_SMQST := 'P'
EndIf
SA2->( MSUnLock() )

Return
