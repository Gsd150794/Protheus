/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Antonio Neves |17/07/2023| Chamado 44400. Todo título de ICM não ser protestado enviando instrução "00" 
Antonio Neves |22/11/2024| Chamado 49206. Adequar ao modelo 2 as instruções do Bradesco
Antonio Neves |10/04/2025| Chamado 50437. Alterar tipo de protesto
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AFIN029
Autor-------------: Julio de Paula Paz
Data da Criacao---: 17/05/2021
Descrição---------: Função que retorna conteúdos específicos para serem utilizados na montagem do arquivo CNab. Chamado 36451.
                    Regra de Retorno dos dados:
                    +--------------------------+
                    |VENDEDOR|CLIENTE|RESULTADO|
                    +--------------------------+
                    |S	     |S	    |6        |
                    +--------------------------+
                    |N	     |S	    |0        |
                    +--------------------------+
                    |S	     |N	    |6        |
                    +--------------------------+
                    |N	     |N	    |0        |
                    +--------------------------+
Parametros--------: _cOpcao = Determina qual opção será tratada e retornada pela função.
Retorno-----------: _cRet   = Conteúdo a ser retornado para o Cnab.
VANDERLEI 21/07/2023
Banco do Brasil
Protestar
	Instrução 1 = "1"
	Instrução 2 = "07"
Não Protestar
	Instrução 1 = "3"
	Instrução 2 = "00"

Bradesco
Protestar
	Instrução 1 = "06"
	Instrução 2 = "07"
Não Protestar
	Instrução 1 = "00"
	Instrução 2 = "00"
	
Itau
Protestar
	Instrução 1 = "34"
	Instrução 2 = "07"
Não Protestar
	Instrução 1 = "10"
	Instrução 2 = "00"

*/
User Function AFIN029(_cOpcao)
Local _cRet := "  "

Begin Sequence 

   If _cOpcao == "INSTPRI"
      //===============================================================
      // Considera estar posicionado no registro da tabela SE1
      //===============================================================
      SA1->(DBSetOrder(1)) // A1_FILIAL+A1_COD+A1_LOJA  
      SA3->(DBSetOrder(1)) // A3_FILIAL+A3_COD 
      
      If ! SA1->(MsSeek(xFilial("SA1")+SE1->(E1_CLIENTE+E1_LOJA)))
         Break
      EndIf

      If ! SA3->(MsSeek(xFilial("SA3")+SE1->E1_VEND1))
         Break
      EndIf
			//NAO PROTESTAR (INCLUINDO OS TITULOS DE ICM)
			If (SA1->A1_I_PRTCB == 'N' .Or. SA3->A3_I_PRTCB == 'N') .Or. SE1->E1_TIPO == "ICM"
				If SE1->E1_PORTADO == "001"  //BANCO DO BRASIL
					_cRet := "3"
				ElseIf SE1->E1_PORTADO == "237" //BRADESCO
					If MV_PAR09 == 1
						_cRet := "00"
					Else
						_cRet := "3"
					EndIf
				ElseIf SE1->E1_PORTADO == "341" //ITAU
					_cRet := "10"
				EndIf
			Else  //PROTESTAR
				If SE1->E1_PORTADO == "001" //BANCO DO BRASIL
					_cRet := "1"
				ElseIf SE1->E1_PORTADO == "237" // BRADESCO
					If MV_PAR09 == 1
						_cRet := "06"
					Else
						_cRet := "1"
					EndIf 
				ElseIf SE1->E1_PORTADO == "341" //ITAU
					_cRet := "1"
				EndIf
			EndIf

		ElseIf _cOpcao == "INSTSEC"
			//===============================================================
			// Considera estar posicionado no registro da tabela SE1
			//===============================================================
			SA1->(DBSetOrder(1)) // A1_FILIAL+A1_COD+A1_LOJA
			SA3->(DBSetOrder(1)) // A3_FILIAL+A3_COD

			If ! SA1->(MsSeek(xFilial("SA1")+SE1->(E1_CLIENTE+E1_LOJA)))
				Break
			EndIf

			If ! SA3->(MsSeek(xFilial("SA3")+SE1->E1_VEND1))
				Break
			EndIf

			//NAO PROTESTAR (INCLUINDO OS TITULOS DE ICM)
			If (SA1->A1_I_PRTCB == 'N' .Or. SA3->A3_I_PRTCB == 'N') .Or. SE1->E1_TIPO == "ICM"
				If SE1->E1_PORTADO == "001"  //BANCO DO BRASIL
					_cRet := "00"
				ElseIf SE1->E1_PORTADO == "237" //BRADESCO
					_cRet := "00"
				ElseIf SE1->E1_PORTADO == "341" //ITAU
					_cRet := "00"
				EndIf
			Else  //PROTESTAR
				If SE1->E1_PORTADO == "001" //BANCO DO BRASIL
					_cRet := "07"
				ElseIf SE1->E1_PORTADO == "237" // BRADESCO
					_cRet := "07"
				ElseIf SE1->E1_PORTADO == "341" //ITAU
					_cRet := "07"
				EndIf
			EndIf
		EndIf

	End Sequence

Return _cRet

