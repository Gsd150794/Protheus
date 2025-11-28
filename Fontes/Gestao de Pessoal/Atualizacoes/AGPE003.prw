/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AGPE003
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 04/09/2025
Descrição---------: Altera Funcionários para permitir Contribuição Assistencial (RA_ASSIST). Chamado 51643
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGPE003

Local _aArea    := FWGetArea() As Array
Local _aAreaSRA := SRA->(FWGetArea()) As Array
Local _oSelf    := Nil As Object

//Cria interface principal
tNewProcess():New('AGPE003'			,; // cFunction. Nome da função que está chamando o objeto
					'Ajusta campo Contr. Assis',; // cTitle. Título da árvore de opções
					{|_oSelf| AGPE003P(_oSelf) },; // bProcess. Bloco de execução que será executado ao confirmar a tela
					'Rotina responsável por modificar o conteúdo do campo Contr. Assis (RA_ASSIST) com base em CSV separado por vírgula. Layout: '+CRLF+; 
               'Fil;Matricula;Nome;Dt. Adm.;Dt.Afast;Contr. Assis'	,; // cDescription. Descrição da rotina
					'AGPE003'				,; // cPerg. Nome do Pergunte (SX1) a ser utilizado na rotina
					{}						,; // aInfoCustom. Informações adicionais carregada na árvore de opções. Estrutura:[1] - Nome da opção[2] - Bloco de execução[3] - Nome do bitmap[4] - Informações do painel auxiliar.
					.F.						,; // lPanelAux. Se .T. cria um novo painel auxiliar ao executar a rotina
					0						,; // nSizePanelAux. Tamanho do painel auxiliar, utilizado quando lPanelAux = .T.
					''						,; // cDescriAux. Descrição a ser exibida no painel auxiliar
					.T.						,; // lViewExecute. Se .T. exibe o painel de execução. Se falso, apenas executa a função sem exibir a régua de processamento
					.T.						,; // lOneMeter. Se .T. cria apenas uma régua de processamento
					.T.						)  // lSchedAuto. Se .T. habilita o botão de processamento em segundo plano (execução ocorre pelo Scheduler)

FWRestArea(_aAreaSRA)
FWRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa----------: AGPE003P
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 08/08/2025
Descrição---------: Realiza o processamento da rotina.
Parametros--------: _oSelf
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGPE003P(_oSelf as Object)

Local _aCabec  := {} As Array
Local _cAux    := '' As Character
Local _oFile   := Nil As Object
Local _aDados	:= {} As Array
Local _aAux		:= {} As Array
Local _nQtdReg	:= 0 As Numeric
Local _nI		:= 0 As Numeric

Private lMsErroAuto		:= .F. As Logical//Variável de controle interno da rotina automática que informa se houve erro durante o processamento.
Private lMsHelpAuto		:= .T. As Logical //Variável que define que o help deve ser gravado no arquivo de log e que as informações estão vindo à partir da rotina automática.

_oFile	:= FwFileReader():New(MV_PAR01)

_oSelf:SaveLog("Inicio do processamento. Arquivo "+AllTrim(MV_PAR01))

If _oFile:Open()
	_aAux := _oFile:GetAllLines() //Acessa todas as Linhas
	//Caso tenha cabeçalho, separo ele
	//Layout do arquivo: Fil;Matricula;NOME;Dt. Adm.;Dt.Afast;Contr. Assis
	If "MATRICULA"$ Upper(_aAux[1])
		ADel(_aAux, 1)
		ASize(_aAux, Len(_aAux) - 1)
	EndIf

	//Separa o Vetor em Nível conforme Token
   For _nI:=1 to Len(_aAux)
		If !Empty(_aAux[_nI])
         aAdd( _aDados , StrTokArr2(_aAux[_nI],';',.T.))
      EndIf
	Next _nx

	_oFile:Close()
	If Empty(_aDados)
		FWAlertError("O arquivo está vazio! Verifique o arquivo e tente novamente.","AGPE00301")
	ElseIf Len(_aDados[1]) <> 6
		FWAlertError("Layout inválido para o arquivo! Verifique o arquivo e tente novamente.","AGPE00302")
	Else
      SRA->(DBSetOrder(1))
		_nQtdReg := Len(_aDados)
		_oSelf:SetRegua1(_nQtdReg)
		For _nI := 1 To _nQtdReg
         _oSelf:IncRegua1("Lendo registros...["+ StrZero(_nI,6) +"] de ["+ StrZero(_nQtdReg,6) +"]" ) 
			lMsErroAuto := .F.
         _aCabec := {}
         If Upper(_aDados[_nI][6])== 'SIM'
            _cSitua := '1'
         Else
            _cSitua := '2'
         EndIf
         If SRA->(DBSeek(_aDados[_nI][1]+_aDados[_nI][2]))
            If _cSitua <> SRA->RA_ASSIST
               aAdd(_aCabec,{"RA_FILIAL",SRA->RA_FILIAL  ,Nil})
               aAdd(_aCabec,{"RA_MAT"   ,SRA->RA_MAT     ,Nil})
               aAdd(_aCabec,{"RA_NOME"   ,SRA->RA_NOME   ,Nil})
               //aAdd(_aCabec,{"RA_PROCES" ,SRA->RA_PROCES ,Nil})
               aAdd(_aCabec,{'RA_ASSIST',_cSitua ,Nil})
               aAdd(_aCabec,{"INDEX"    ,15              ,Nil})
               MSExecAuto({|x,y,k,w| GPEA010(x,y,k,w)},NIL,NIL,_aCabec,4)

               If lMsErroAuto
                  _cAux := 'Erro ao atualizar matrícula '+SRA->RA_MAT
                  _oSelf:SaveLog(_cAux)
                  FWAlertError(_cAux+'. O processo será abortado.')
                  MostraErro()
                  Exit
               EndIf
            EndIf
         Else
            _cAux := 'Matrícula não localizada: '+_aDados[_nI][1]+_aDados[_nI][2]
            FWAlertError(_cAux+'. O processo será abortado.')
            _oSelf:SaveLog(_cAux)
            Exit
         EndIf
      Next _nI
   EndIf
EndIf
_oSelf:SaveLog("Fim do processamento")

Return
