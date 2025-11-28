/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |09/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: F070OWN
Autor-------------: Josué Danich Prestes
Data da Criacao---: 27/04/2017
Descrição---------: P.E. executado durante a montagem do filtro da baixa por lote do contas a receber. Chamado 18417
Parametros--------: Nenhum
Retorno-----------: _cFiltro - Expressão caracter com o filtro a ser utilizado pela IndRegua.
===============================================================================================================================
*/
User Function F070OWN

Local _cFiltro   := ""
Local oCliFinal
Local cCliFinal  := Space(06)
Local oCliInic
Local cCliInic   := Space(06)
Local oLjclieFin
Local cLjclieFin := Space(04)
Local oLjclieIni
Local cLjclieIni := Space(04)
Local oNatFin
Local cNatFin    := Space(10)
Local oNatIni
Local cNatIni    := Space(10)
Local oSay1
Local oSay2
Local oSay3
Local oSay4
Local oSay5
Local oSay6           

Local _nOpca     := 0          

Static _oDlg


DEFINE MSDIALOG _oDlg TITLE "PARÂMETROS ADICIONAIS - PE F070OWN" FROM 000, 000  TO 220, 350 COLORS 0, 16777215 PIXEL

    @ 017, 011 Say oSay1 PROMPT "Cliente de:" SIZE 054, 007 OF _oDlg COLORS 0, 16777215 PIXEL
    @ 025, 011 MSGET oCliInic VAR cCliInic SIZE 061, 08 OF _oDlg COLORS 0, 16777215 F3 "SA1" PIXEL Valid(IIf(Len(AllTrim(cCliInic)) > 0 .And. Upper(cCliInic) <> 'ZZZZZZ',IIf(ExistCPO("SA1",cCliInic),.T.,Eval({|| .F.,oCliInic:SetFocus()})),.T.))
    @ 017, 100 Say oSay2 PROMPT "Loja de:" SIZE 055, 007 OF _oDlg COLORS 0, 16777215 PIXEL
    @ 025, 100 MSGET oLjclieIni VAR cLjclieIni SIZE 061, 08 OF _oDlg COLORS 0, 16777215 PIXEL
    @ 047, 011 Say oSay3 PROMPT "Cliente ate:" SIZE 058, 007 OF _oDlg COLORS 0, 16777215 PIXEL
    @ 055, 011 MSGET oCliFinal VAR cCliFinal SIZE 061, 08 OF _oDlg COLORS 0, 16777215 F3 "SA1" PIXEL Valid(IIf(Len(AllTrim(cCliFinal)) > 0 .And. Upper(cCliFinal) <> 'ZZZZZZ',IIf(ExistCPO("SA1",cCliFinal),.T.,Eval({|| .F.,oCliFinal:SetFocus()})),.T.))
    @ 047, 100 Say oSay4 PROMPT "Loja ate:" SIZE 025, 007 OF _oDlg COLORS 0, 16777215 PIXEL
    @ 055, 100 MSGET oLjclieFin VAR cLjclieFin SIZE 061, 08 OF _oDlg COLORS 0, 16777215 PIXEL
    @ 077, 011 Say oSay5 PROMPT "Bordero de:" SIZE 062, 007 OF _oDlg COLORS 0, 16777215 PIXEL
    @ 085, 011 MSGET oNatIni VAR cNatIni SIZE 061, 08 OF _oDlg COLORS 0, 16777215 F3 "SED" PIXEL
    @ 077, 100 Say oSay6 PROMPT "Bordero ate:" SIZE 060, 007 OF _oDlg COLORS 0, 16777215 PIXEL
    @ 085, 100 MSGET oNatFin VAR cNatFin SIZE 061, 08 OF _oDlg COLORS 0, 16777215 F3 "SED" PIXEL

Activate MSDialog _oDlg Centered On Init EnchoiceBar(_oDlg, {|| _nOpca := 1, _oDlg:End()}, {|| _nOpca := 2, _oDlg:End()},,)

//=================================================================================
// Filtros do padrão que não serão executados por conta da existência desse PE
//=================================================================================

_cFiltro += 'E1_FILIAL+E1_PORTADO+E1_AGEDEP+E1_CONTA=="'+xFilial("SE1")+cBancoLt+cAgenciaLt+cContaLt+'".And.'

_cFiltro += 'DToS(E1_VENCREA)>="'+DToS(dVencDe) + '".And.'
_cFiltro += 'DToS(E1_VENCREA)<="'+DToS(dVencAte)+ '".And.'

If !(Empty(cNatDe) .And. Empty(cNatAte) )

  _cFiltro += 'E1_NATUREZ>="'      +cNatDe       + '".And.'
  _cFiltro += 'E1_NATUREZ<="'      +cNatAte      + '".and.'

EndIf

_cFiltro += '!(E1_TIPO$"'+MVPROVIS+"/"+MVRECANT+"/"+MVIRABT+"/"+MVINABT+"/"+MV_CRNEG

//Destarcar Abatimentos
If MV_PAR06 == 2
	_cFiltro += "/"+MVABATIM+"/"+MVFUABT +'")' //adicionado MVFUABT pois a variael MVABATIM na estaretornando FU-
Else
	_cFiltro += '")'
EndIf

// Verifica integracao com TMS e nao permite baixar titulos que tenham solicitacoes
// de transferencias em aberto.
_cFiltro += ' .And. Empty(E1_NUMSOL)'
_cFiltro += ' .And. (E1_SALDO>0 .Or. E1_OK="xx")'

//Filtro personalizado se confirmar a tela
If _nOpca == 1 
    If !(Empty(cCliInic) .And. Empty(cCliFinal) )
		_cFiltro += " .And. E1_CLIENTE >= '"       + cCliInic   + "' .And. E1_CLIENTE <= '" + cCliFinal  + "'" 
	EndIf
	 If !(Empty(cLjclieIni) .And. Empty(cLjclieFin) )
		_cFiltro += " .And. E1_LOJA >= '"       + cLjclieIni   + "' .And. E1_LOJA <= '" + cLjclieFin  + "'" 
	EndIf
	If !(Empty(cNatIni) .And. Empty(cNatIni) )
		_cFiltro += " .And. E1_NUMBOR  >= '"       + cNatIni   + "' .And. E1_NUMBOR  <= '" + cNatIni  + "'" 
	EndIf

EndIf

Return _cFiltro
