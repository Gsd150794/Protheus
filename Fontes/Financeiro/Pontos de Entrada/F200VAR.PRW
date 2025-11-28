/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Antonio Neves |14/08/2023| Alteração incorreto do leiaute de envio do CNAB causou a necessidade de o retorno procurar o IDCNAB
						 | pelo número do Título. Somente Casos do Bradesco e para Ocorrência 06 - Baixa
Antonio Neves |05/12/2023| Chamado 45779 - Readequação do leiatute de retonno para atender a impressão do número do título
 							na posição correta. A Customização visa atender todos os títulos já enviados.
							Posições atuais no leiaute de envio e o campo adequado
							038-062 EXECBLOCK("IDENTIT",.F.,.F.) --->>>  (SE1->E1_IDCNAB)                
							111-120 SE1->E1_IDCNAB --->>> (SE1->E1_NUM)      
							Posições corretas no arquivo de retorno
							117-126 --->> 038-062
=================================================================================================================================================================================================
Analista       - Programador   - Inicio   - Envio    - Chamado - Motivo da Alteração
=================================================================================================================================================================================================
Antonio Ramos  - Igor Melgaço  - 15/08/25 - 15/10/25 - 51344   - Ajuste para considerar juros caso o cliente tenha abatimento o mesmo só vem o valor residual referente a diferença entre desconto contratual e juros pago. 
=================================================================================================================================================================================================
*/

#Include "TOTVS.ch"
#Include 'TOPCONN.CH'

//-------------------------------------------------------------------------------
/*/{Protheus.doc} F200VAR
Manipular as informações (variáveis) no retorno do Cnab a Receber (FINA200). 
 
@ParamIXB aDados[1] = Número do Título    | Variavel de origem: cNumTit
          aDados[2] = Data da Baixa       | Variavel de origem: dBaixa
          aDados[3] = Tipo do Título      | Variavel de origem: cTipo
          aDados[4] = Nosso Número        | Variavel de origem: cNsNum (NUMBCO)
          aDados[5] = Valor da Despesa    | Variavel de origem: nDespes
          aDados[6] = Valor do Desconto   | Variavel de origem: nDescont
          aDados[7] = Valor do Abatimento | Variavel de origem: nAbatim
          aDados[8] = Valor Recebido      | Variavel de origem: nValRec
          aDados[9] = Juros               | Variavel de origem: nJuros
          aDados[10] = Multa              | Variavel de origem: nMulta
          aDados[11] = Outras Despesas    | Variavel de origem: nOutrDesp
          aDados[12] = Valor do Credito   | Variavel de origem: nValCc
          aDados[13] = Data do Credito    | Variavel de origem: dDataCred
          aDados[14] = Ocorrência         | Variavel de origem: cOcorr
          aDados[15] = Motivo do banco    | Variavel de origem: cMotBan
          aDados[16] = Linha Inteira      | Variavel de origem: xBuffer
          aDados[17] = Data de Vencimento | Variavel de origem: dDtVc
 
/*/
//-------------------------------------------------------------------------------

User Function F200VAR()

	Local aDados        := ParamIXB As Array
	Local aAreaSE1      := SE1->(GetArea()) As Array
	Local _cOcorren     := ParamIXB[1][14] As Character

	DBSelectArea("SE1")
	SE1->( DBSetOrder(16) ) // E1_Filial + E1_IDCNAB
	If cBanco == "237" .AND. Alltrim(_cOcorren) == "06"
		If SE1->(DBSeek(xFilial("SE1")+cNumTit))
			If nDescont > 0 .And. nDescont < SE1->E1_I_DESCO
				nJuros := SE1->E1_I_DESCO - nDescont
				nDescont := 0
			Else
				nDescont := 0
			EndIf
		EndIf

		RestArea(aAreaSE1)
	EndIf

Return(aDados)
