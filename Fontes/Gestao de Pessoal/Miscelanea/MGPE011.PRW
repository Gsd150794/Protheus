/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |02/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
Lucas Borges  |16/10/2024| Chamado 48867. Refatoração do fonte
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MGPE011
Autor-------------: Alexandre Villar
Data da Criacao---: 22/05/2014
Descrição---------: Importa o arquivo da Unimed
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGPE011()

Local _cPerg as String
Local _oSelf as Object

_cPerg		:= "MGPE011"
//============================================
//Cria interface principal
//============================================
tNewProcess():New(	_cPerg											,; // Função inicial
					"Importação do Arquivo de Débitos da Unimed [CSV]",; // Descrição da Rotina
					{|_oSelf| MGPE011P(_oSelf) }					,; // Função do processamento
					"Essa rotina permite fazer a importação dos débitos da Unimed.",; // Descrição da Funcionalidade
					_cPerg											,; // Configuração dos Parâmetros
					{}												,; // Opções adicionais para o painel lateral
					.F.												,; // Define criação do Painel auxiliar
					0												,; // Tamanho do Painel Auxiliar
					''												,; // Descrição do Painel Auxiliar
					.T.												,; // Se .T. exibe o painel de execução. Se falso, apenas executa a função sem exibir a régua de processamento.
                    .T.                                              ) // Se .T. cria apenas uma regua de processamento.

Return

/*
===============================================================================================================================
Programa----------: MGPE011TXT
Autor-------------: Alexandre Villar
Data da Criacao---: 22/05/2014
Descrição---------: Monta os dados e prepara o processamento
Parametros--------: _oSelf -> O -> Objeto da Tela
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGPE011P(_oSelf)

Local _aAux		as Array
Local aColAux	as Array
Local aHeader	as Array
Local nRegVal	as Number
Local _nX		as Number
Local _oFile	as Object
_aAux:={}
aColAux:={}
aHeader:={}

_oSelf:SetRegua1(1)
_oSelf:IncRegua1("Lendo arquivo...")
_oFile := FwFileReader():New(MV_PAR01)
If _oFile:Open()
	_aAux := _oFile:GetAllLines() //Acessa todas as Linhas
	_oFile:Close()
	For _nX:=2 to Len(_aAux)//Processa descartando o cabeçalho
		aAdd( aColAux , StrTokArr2(_aAux[_nX],';',.T.))
	Next _nx
	If Empty( aColAux )
		FWAlertWarning("Não foram encontrados registros válidos para exibir! Verifique o arquivo e tente novamente.","MGPE01103")
	Else
		nRegVal := Len( aColAux )
	
		aHeader:= StrTokArr2(_aAux[1],';')//aHeader := aColAux[1]

		If U_ITListBox( "Leitura do Arquivo da Unimed: ["+ StrZero( nRegVal , 9 ) +"] registros." , aHeader , aColAux , .T. )
			If !Empty(aHeader) .And. !Empty( aColAux )
				MGPE011PRC(_oSelf,aHeader,aColAux )
			Else
				FWAlertWarning("Não foram encontrados registros para processar!","MGPE01104")
			EndIf
		Else
			FWAlertInfo("Operação cancelada pelo usuário!","MGPE01105")
		EndIf
	EndIf
Else
	FWAlertWarning("O arquivo está vazio ou é inválido para análise! Verifique o arquivo e tente novamente.","MGPE01101")
EndIf

Return

/*
===============================================================================================================================
Programa----------: MGPE011PRC
Autor-------------: Alexandre Villar
Data da Criacao---: 22/05/2014
Descrição---------: Importa o arquivo da Unimed
Parametros--------: _oSelf -> O -> Objeto da Tela
					aHeader -> A -> Cabeçalho dos campos
					aColAux -> A -> Registros a serem importados
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGPE011PRC(_oSelf,aHeader,aColAux)

Local aLogDif	as Array
Local aDados	as Array
Local cAlias	as String
Local cFil		as String
Local cMatric	as String
Local cNome		as String
Local _cOrigem	as String
Local _cPD		as String
Local cCPF		as String
Local cSeqDEP	as String
Local nValor	as String
Local nI		as Number
Local _nX		as Number
Local nPosMAT	as Number
Local nPosNOM	as Number
Local nPosCPF	as Number
Local nPosDEP	as Number
Local nPosVAL	as Number
Local nTotReg	as Number

aLogDif:={}
aDados:={}
cAlias	:= GetNextAlias()
nPosMAT	:= aScan( aHeader , "MATRICULA_DO_BENEFICIARIO"	)
nPosNOM	:= aScan( aHeader , "NOME_TITULAR"				)
nPosCPF	:= aScan( aHeader , "CPF_TITULAR"				)
nPosDEP	:= aScan( aHeader , "GRAU_DEPENDENCIA"			)
nPosVAL	:= aScan( aHeader , "VLR_PARTICIPACAO"			)
nTotReg	:= Len( aColAux )

//Verifica os posicionamentos indispensáveis do arquivo
If nPosMAT == 0 .Or. nPosCPF == 0 .Or. nPosDEP == 0 .Or. nPosVAL == 0
	FWAlertWarning("O arquivo está vazio ou o Layout é inválido para análise! Verifique o arquivo e tente novamente.","MGPE01107")
	Return
EndIf

DBSelectArea('RHO')
//Ordena os dados e inicializa o processamento
aSort( aColAux ,,, {|x,y| x[nPosMAT] + x[nPosDEP] > y[nPosMAT] + y[nPosDEP] } )
_oSelf:SetRegua1(nTotReg)

Begin Transaction

//Processa os registros do arquivo
For nI := 1 To Len( aColAux )

	_oSelf:IncRegua1("Processando...["+ StrZero( nI , 6 ) +"] de ["+ StrZero( nTotReg , 6 ) +"]")
	
	cMatric	:= PadL( AllTrim(	aColAux[nI][nPosMAT] ) , TamSX3("RA_FILIAL")[01] + TamSX3("RA_MAT")[01] , "0" )
	cFil 	:= SubStr(cMatric,1,TamSX3("RA_FILIAL")[01])
	cMatric	:= SubStr(cMatric,TamSX3("RA_FILIAL")[01]+1,TamSX3("RA_MAT")[01])
	cNome	:= AllTrim(			aColAux[nI][nPosNOM] )
	cCPF	:= PadL(AllTrim(			aColAux[nI][nPosCPF] ),TamSX3("RA_CIC")[01],"0")
	cSeqDEP	:= AllTrim(			aColAux[nI][nPosDEP] )
		
	//Verificação dos Funcionários - Titulares
	BeginSql alias cAlias
		SELECT SRA.R_E_C_N_O_ AS REGSRA , RHK.R_E_C_N_O_ AS REGRHK 
		FROM %Table:SRA% SRA 
		LEFT JOIN %Table:RHK% RHK ON
		SRA.RA_FILIAL = RHK.RHK_FILIAL
		AND SRA.RA_MAT = RHK.RHK_MAT
		WHERE SRA.D_E_L_E_T_ = ' '
		AND RHK.D_E_L_E_T_ = ' '
		AND	SRA.RA_FILIAL = %exp:cFil%
		AND	SRA.RA_MAT = %exp:cMatric%
		AND	SRA.RA_CIC LIKE %exp:cCPF%
	EndSql

	If (cAlias)->( !Eof() )
		If Empty( (cAlias)->REGSRA ) .Or. Empty( (cAlias)->REGRHK )
			aAdd( aLogDif , {cMatric,cNome,"Registro não encontrado no Protheus!",IIf(Empty((cAlias)->REGSRA),'Não','Sim'),IIF(Empty((cAlias)->REGRHK),'Não','Sim')})
		Else
			aDados := {0,0,0}
			While nI <= Len(aColAux) .And. cFil+cMatric == PadL( AllTrim( aColAux[nI][nPosMAT] ) , TamSX3("RA_FILIAL")[01] + TamSX3("RA_MAT")[01] , "0" )
				nValor := Val( StrTran( StrTran( aColAux[nI][nPosVAL] , '.' , '' ) , ',' , '.' ) )
				Do Case
					Case AllTrim( aColAux[nI][nPosDEP] ) == '0' .And. nValor > 0
						aDados[01] += nValor
					Case AllTrim( aColAux[nI][nPosDEP] ) <> '0' .And. nValor > 0
						aDados[02] += nValor
					Case nValor < 0
						aDados[03] += ABS( nValor )
				EndCase
				nI++
			EndDo
			nI--
			For _nX := 1 To 3
				If aDados[_nX] > 0
					_cOrigem := IIf(_nX==1.Or._nX==2,'1','2')
					_cPD	:= IIf(_nX==1,'509',IIf(_nX==2,'513','348'))
					If RHO->(DBSeek(cFil+cMatric+DToS(dDataBase)+'1'+'99 '+_cOrigem+_cPD+SubStr( DToS(dDataBase) , 1 , 6 )))
						aAdd( aLogDif , {cMatric,cNome,"Registro já cadastrado no Protheus",,})
					Else
						RHO->( RecLock('RHO',.T.) )
						RHO->RHO_FILIAL	:= cFil
						RHO->RHO_MAT	:= cMatric
						RHO->RHO_DTOCOR	:= dDataBase
						RHO->RHO_ORIGEM	:= _cOrigem
						RHO->RHO_TPFORN	:= '1'
						RHO->RHO_CODFOR	:= '99'
						RHO->RHO_TPLAN	:= '1'
						RHO->RHO_PD		:= _cPD
						RHO->RHO_VLRFUN	:= aDados[_nX]
						RHO->RHO_COMPPG	:= SubStr( DToS(dDataBase) , 1 , 6 )
						RHO->RHO_OBSERV	:= 'Importação Automática - Arquivo Unimed'
						RHO->( MSUnLock() )
					EndIf
				EndIf
			Next _nX
		EndIf
	Else
		aAdd( aLogDif , {cMatric,cNome,"Registro não encontrado no Protheus!",IIf(Empty((cAlias)->REGSRA),'Não','Sim'),IIf(Empty((cAlias)->REGRHK),'Não','Sim')})
	EndIf
	(cAlias)->(DBCloseArea())
Next nI

End Transaction

If Empty( aLogDif )
	FWAlertSuccess("Todos os registros foram importados com sucesso!","MGPE01108")
Else
	LjMsgRun( "Verificando as inconsistências..." , "Aguarde!" , {|| U_ITListBox( "Status dos Processamentos" , {"Matrícula","Nome","Situação","Funcionário","Plano"} , aLogDif , .T. ) } )
EndIf

Return
