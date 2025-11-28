/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Josué Danich  |18/10/2017| Chamado 22056. Mudança de ordem da legenda de bloqueio cnab
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: FINALEG
Autor-------------: Josué Danich Prestes
Data da Criacao---: 14/11/2016
Descrição---------: Ponto de entrada para refazer a legenda padrão da rotina Contas a Receber. Chamado 16924
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function FINALEG

Local nReg     := ParamIXB[1]
Local cAlias   := ParamIXB[2]
Local aLegenda := { {"BR_VERDE"		,	"Titulo em aberto"							},;
					{"BR_AZUL"		,	"Baixado parcialmente"						},;
					{"BR_VERMELHO"	,	"Titulo Baixado"							},;
					{"BR_PRETO"		,	"Titulo em Bordero"							},;
					{"BR_BRANCO"	,	"Adiantamento com saldo"					},;
					{"BR_CINZA"		,	"Titulo baixado parcialmente e em bordero"	},;
					{"BR_MARROM"	,	"Adiantamento de Imp. Bx. com saldo"		} }
Local uRetorno := .T.

If nReg = Nil	// Chamada direta da funcao onde nao passa, via menu Recno eh passado
	uRetorno := {}
	If cAlias = "SE1"   
		
   		aAdd(aLegenda, {"BR_LARANJA","Titulo Bloqueado por Cnab"})
		aAdd(aLegenda, {"BR_AMARELO", "Titulo Protestado"})

		aAdd(uRetorno, { 'Round(E1_SALDO,2) = 0'																			, aLegenda[3][1]	} ) //"Titulo Baixado" 
		aAdd(uRetorno, { '!Empty(E1_NUMBOR) .and.(Round(E1_SALDO,2) # Round(E1_VALOR,2))'									, aLegenda[6][1]	} ) //"Titulo baixado parcialmente e em bordero"
		aAdd(uRetorno, { 'E1_TIPO == "'+MVRECANT+'".and. Round(E1_SALDO,2) > 0 .And. !FXAtuTitCo()'							, aLegenda[5][1]	} ) //"Adiantamento com saldo"
		aAdd(uRetorno, { '!Empty(E1_NUMBOR)'																				, aLegenda[4][1]	} ) //"Titulo em Bordero"
		aAdd(uRetorno, { 'Round(E1_SALDO,2) # Round(E1_VALOR,2) .And. !FXAtuTitCo() '										, aLegenda[2][1]	} ) //"Baixado parcialmente"
		aAdd(uRetorno, { 'U_CNABBL()'																						, aLegenda[8][1]	} ) //"Bloqueado Cnab"
		aAdd(uRetorno, { 'Round(E1_SALDO,2) == Round(E1_VALOR,2) .And. E1_SITUACA == "F" '									, aLegenda[Len(aLegenda)][1]	} ) //"Titulo Protestado"

		aAdd(uRetorno, { '.T.', aLegenda[1][1] } )
	Else
		If GetMv("MV_CTLIPAG")           
			aAdd(aLegenda, {"BR_AMARELO", "Titulo aguardando liberacao"})
			aAdd(uRetorno, { ' !( SE2->E2_TIPO $ MVPAGANT ).and. Empty(E2_DATALIB) .And. (SE2->E2_SALDO+SE2->E2_SDACRES-SE2->E2_SDDECRE) > GetMV("MV_VLMINPG") .And. E2_SALDO > 0', aLegenda[Len(aLegenda)][1] } ) 
		EndIf
						
		aAdd(uRetorno, { 'E2_TIPO $ "INA/'+MVTXA+'" .And. Round(E2_SALDO,2) > 0 .And. E2_OK == "TA"  ', aLegenda[7][1] } )			
		aAdd(uRetorno, { 'E2_TIPO == "'+MVPAGANT+'" .And. Round(E2_SALDO,2) > 0', aLegenda[5][1] } )			
		aAdd(uRetorno, { 'Round(E2_SALDO,2) + Round(E2_SDACRES,2)  = 0', aLegenda[3][1] } )
		aAdd(uRetorno, { '!Empty(E2_NUMBOR) .and.(Round(E2_SALDO,2)+ Round(E2_SDACRES,2) # Round(E2_VALOR,2)+ Round(E2_ACRESC,2))', aLegenda[6][1] } )						
		aAdd(uRetorno, { '!Empty(E2_NUMBOR)', aLegenda[4][1] } )
		aAdd(uRetorno, { 'Round(E2_SALDO,2)+ Round(E2_SDACRES,2) # Round(E2_VALOR,2)+ Round(E2_ACRESC,2)', aLegenda[2][1] } )
		aAdd(uRetorno, { '.T.', aLegenda[1][1] } )
	EndIf
Else
	If cAlias = "SE1"
		aAdd(aLegenda, {"BR_LARANJA","Titulo Bloqueado por Cnab"})
		aAdd(aLegenda, {"BR_AMARELO", "Titulo Protestado"})
    Else 
    	If GetMv("MV_CTLIPAG")    
    		aAdd(aLegenda, {"BR_AMARELO",  "Titulo aguardando liberacao"})
    	EndIf
	EndIf
	BrwLegenda(cCadastro, "Contas a Receber - Legenda", aLegenda)
EndIf

Return uRetorno

/*
===============================================================================================================================
Programa----------: CNABBL
Autor-------------: Josué Danich Prestes
Data da Criacao---: 14/11/2016
Descrição---------: Teste de bloqueio cnab do titulo posicionado
Parametros--------: Nenhum
Retorno-----------: _lRet - se o título está bloqueado por regra cnab
===============================================================================================================================
*/

User Function Cnabbl()

Local _lRet := .F.

If Empty(AllTrim(SE1->E1_NUMBCO)) 
			
		If !Empty(AllTrim(SE1->E1_IDCNAB)) .Or. !Empty(AllTrim(SE1->E1_I_NUMBC))

			_lRet := .T.
			
		EndIf
	
EndIf

Return _lRet
