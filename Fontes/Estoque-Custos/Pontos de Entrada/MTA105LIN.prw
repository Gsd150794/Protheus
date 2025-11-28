/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |17/01/2024| Chamado 46095. Ajuste na validação do centro de custo ser válido com campo de investimento.
Igor Melgaço  |16/07/2025| Chamado 51382. Ajustes para preenchimento obrigatório do campo Motivo (CP_I_MOTIV).
Lucas Borges  |19/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MTA105LIN
Autor-------------: Guilherme Diogo 
Data da Criacao---: 07/01/2013 
Descrição---------: Ponto de entrada que valida linha digitada na rotina de Solicitacao ao Armazem. 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MTA105LIN() as Logical

Local _lRet   := .T. As Logical
Local _cProd  := AllTrim(aCols[n][aScan(aHeader,{|x| Upper(AllTrim(x[2])) == "CP_PRODUTO"})]) As Character
Local _cArmz  := AllTrim(aCols[n][aScan(aHeader,{|x| Upper(AllTrim(x[2])) == "CP_LOCAL"})]) As Character
Local _nQtdAt := aCols[n][aScan(aHeader,{|x| Upper(AllTrim(x[2])) == "CP_QUANT"})] As Numeric
Local _nQtdAt2:= aCols[n][aScan(aHeader,{|x| Upper(AllTrim(x[2])) == "CP_QTSEGUM"})] As Numeric
Local _cMotiv := aCols[n][aScan(aHeader,{|x| Upper(AllTrim(x[2])) == "CP_I_MOTIV"})] As Character
Local _nSaldo := 0 As Numeric
Local _nQuant := 0 As Numeric
Local _nSolic := 0 As Numeric
Local _nI     := 0 As Numeric
Local _aArea  := FWGetArea() As Array
Local _cmens	:= "" As Character
Local _cCC		:= "" As Character
Local _cINVES := "" As Character
Local _cLOCIN := "" As Character
Local _lexcep := .F. As Logical
Local _cloca  := SuperGetMV("IT_MOTINV",.F.,"15") As Character
Local _cArmazens:= SuperGetMV('IT_ARMCPR',.F.,"02,04") As Character
Local _cUM_NO_Fracionada:=SuperGetMV("IT_UMNOFRAC",.F.,"PC,UN") As Character // parametro de unidades de medida para fracionamento           
Local _lValidFrac1UM:=.T. As Logical

Begin Sequence

If (_cArmz $ _cArmazens)
   U_ITMsg("Para o armazém "+_cArmz+" não é permitido a inclusão de SAs. Armazens não permitidos: '"+AllTrim(_cArmazens)+"'.",;
           "Permissões de Acesso Italac",;
           "Entre em contato com o departamento de Custo.",1)
    _lRet := .F.
    Break
Else
   ZZL->(DBSetOrder(3))  
   If ZZL->(DBSeek(xFilial("ZZL")+RetCodUsr()))
      If !(_cArmz $ ZZL->ZZL_ARMAZE)
             U_ITMsg("Usuário sem permissão para utilizar este armazem. Não será possível realizar a SA. Armazens permitidos ao usuário: '"+AllTrim(ZZL->ZZL_ARMAZE)+"'.",;
                     "Permissões de Acesso Italac",;
                     "Entre em contato com o suporte do TI.",1)
             _lRet := .F.
             Break
      EndIf
   EndIf   
EndIf

If (Upper(FunName()) == "MATA105" .Or. Upper(FunName()) == "AEST015") .And. !FWIsInCallStack("MSEXECAUTO") .And. Empty(AllTrim(_cMotiv))
   U_ITMsg("É obrigatório o preenchimento do campo Cod Motivo.",;
         'Atenção!',;
         "Prencha o campo Cod Motivo.",1)
   _lRet := .F.
   Break
EndIf

//============================================================
//Calcula o saldo disponivel do produto.      
//============================================================

SB2->(DBSetOrder(1))

_aSaldo := {}

If SB2->(DBSeek(xFilial("SB2")+PadR(_cProd,15)+_cArmz))
   FWMsgRun(, {|| _aSaldo := Calcest(_cProd,_cArmz,Date()+1)}, "Aguarde...", "Validando estoque....")
   _nsaldo := _aSaldo[1] - SB2->B2_RESERVA - SB2->B2_QACLASS - SB2->B2_QEMPSA - SB2->B2_QEMP
   If _nsaldo < 0
      _nsaldo := 0
   EndIf
Else
   _nSaldo := 0
EndIf 

ZZL->(DBSetOrder(3))  
ZZL->(DBSeek(xFilial("ZZL")+RetCodUsr()))
If ZZL->ZZL_PEFROU == "S"
   _lValidFrac1UM:=.F.
EndIf

//============================================================
//Valida quantidade fracionada.
//============================================================
If _lValidFrac1UM
   SB1->(DBSeek(xFilial("SB1") + AllTrim(_cProd)))
   If  SB1->B1_UM $ _cUM_NO_Fracionada
      If _nQtdAt <> Int(_nQtdAt) .And. !GDDeleted(n) 
         _lRet := .F.
         U_ITMsg("O produto / linha " + AllTrim(_cProd) + " / " + AllTrim(Str(n)) + " não pode ter quantidade 1um fracionada.",;
           "Quantidade inválida",;
           "Favor ajustar a quantidade 1um para uma quantidade inteira.",1) 
           Break
      EndIf
   EndIf
   If  SB1->B1_SEGUM $ _cUM_NO_Fracionada
      If _nQtdAt2 <> Int(_nQtdAt2) .And. !GDDeleted(n)
         _lRet := .F.
         U_ITMsg("O produto / linha " + AllTrim(_cProd) + " / " + AllTrim(Str(n)) + " não pode ter quantidade 2um fracionada.",;
            "Quantidade inválida",;
            "Favor ajustar a quantidade 2um para uma quantidade inteira.",1) 
         Break
      EndIf
   EndIf
EndIf

//============================================================
//Solicitacoes nao atendidas.                 
//============================================================

_nSolic := CalcSolic(cA105Num,_cProd,_cArmz)

//============================================================
//CALCULA QUANTIDADE DIGITADA DO PRODUTO NA SOLICITACAO.
//============================================================

For _nI := 1 To Len(aCols)
   If _nI <> n .And. AllTrim(aCols[_nI][aScan(aHeader,{|x| Upper(AllTrim(x[2])) == "CP_PRODUTO"})]) == _cProd .And. !aCols[_nI][Len(aHeader)+1]
      If AllTrim(aCols[_nI][aScan(aHeader,{|x| Upper(AllTrim(x[2])) == "CP_LOCAL"})]) == _cArmz
         _nQuant += aCols[_nI][aScan(aHeader,{|x| Upper(AllTrim(x[2])) == "CP_QUANT"})]
      EndIf	
   EndIf
Next _nI

If _nSaldo - _nSolic - _nQuant - _nQtdAt < 0 .And. _lRet
   U_ITMsg("Já existem solicitações a serem atendidas para esse produto." + CRLF + CRLF + ;
            " Saldo atual: "+Transform(_nSaldo,'@E 999,999,999.99') + CRLF + CRLF + ;
            " Total solicitações incluindo esta: "+Transform(_nSolic+_nQuant+_nQtdAt,'@E 999,999,999.99');
            ,"Saldo Indisponível",	"Dúvidas, consulte o Almoxarifado.",1)
     
   _lRet := .F.
   Break
EndIf

//============================================
//Faz validação de campos de investimento
//============================================
If !(acols[n][Len(aheader)+1])
   //lê campos
   _cCC 		:= acols[n][aScan(aHeader , {|X| Upper( AllTrim( X[2] ) ) == "CP_CC"     } )]
   _cINVES	:= acols[n][aScan(aHeader , {|X| Upper( AllTrim( X[2] ) ) == "CP_I_INVES"     } )]
   _cLOCIN	:= acols[n][aScan(aHeader , {|X| Upper( AllTrim( X[2] ) ) == "CP_I_LOCIN"     } )]
   _cMOTIN	:= acols[n][aScan(aHeader , {|X| Upper( AllTrim( X[2] ) ) == "CP_I_MOTIV"     } )]
   
   //verifica se é exceção de validação
   If 	AllTrim(_cMOTIN) $ AllTrim(_cloca) 
      _lexcep := .T.
   EndIf

   //Verifica se campo de centro de custo é válido com campo de investimento
   If SubStr(AllTrim(_cCC),1,5) $ AllTrim(u_vldcc())   .And. _cINVES <> "S" .And. !(Empty( _cCC )) .And. !(_lexcep) .And. !FWIsInCallStack( "MDTA695" )
      _cmens += "Item " + StrZero(n,4) + " - Para Centro de custo da filial é preciso que seja solicitação de investimento." + CRLF + CRLF
      _lRet := .F.
   EndIf

   //Verifica se campo de centro de custo é válido com campo de investimento
   If !(SubStr(AllTrim(_cCC),1,5) $ AllTrim(_cCC))  .And. _cINVES = "S" .And. !(_lexcep)
      _cmens += "Item " + StrZero(n,4) + " - Para investimento é preciso campo de centro de custo válido." + CRLF + CRLF
      _lRet := .F.
   EndIf

   //Verifica se campo investimento não está como S se o campo Local de investimento estiver preenchido
   If  _cINVES <> "S" .And. !(Empty( _cLOCIN )) 
      _cmens += "Item " + StrZero(n,4) + " - Para ter Local de investimento é preciso ser solicitação de investimento." + CRLF + CRLF
      _lRet := .F.
   EndIf

   //Verifica se campo Local de investimento está preenchido se campo investimento está preenchido
   If  _cINVES = "S"  .And. (Empty( _cLOCIN )) 
      _cmens += "Item " + StrZero(n,4) + " - Para solicitação de investimento é obrigatório Local de investimento." + CRLF + CRLF
      _lRet := .F.
   EndIf

   //Se Local de investimento está preenchido garante que a descrição de investimento está preenchida
   If  _cINVES = "S"	.And. !(Empty( _cLOCIN )) .And. !(_lexcep) 
      acols[n][aScan(aHeader , {|X| Upper( AllTrim( X[2] ) ) == "CP_I_DESIN"     } )] := 	Posicione("ZZI",1,xFilial("ZZI")+_cLOCIN,"ZZI_DESINV")
   EndIf
EndIf

//============================================
//Mostra lista de itens com problema
//============================================
If !(_lRet) .And. !(Empty(_cmens))
   U_ITMsg( 'Problemas nos itens abaixo: ' + CRLF + CRLF + _cmens , 'Atenção!',;
               'Caso necessário solicite a manutenção à um usuário com acesso ou, se necessário, solicite o acesso à área de TI/ERP.' ,1 )
   Break
EndIf

End Sequence

FWRestArea(_aArea)

Return _lRet

/*
===============================================================================================================================
Programa----------: CalcSolic
Autor-------------: Guilherme Diogo 
Data da Criacao---: 07/01/2013 
Descrição---------: Calcula solicitacoes nao atendidas.
Parametros--------: 	_cNumSA - Numero da SA
                  _cProd - Produto
                  _cArmz - Armazém
Retorno-----------:  _nQtd - Quantidade não atendida
===============================================================================================================================
*/
Static Function CalcSolic(_cNumSA As Character, _cProd As Character, _cArmz As Character) As Numeric

Local _nQtd      := 0 As Numeric
Local _cQuery    := "" As Character
Local _cAliasSCP := GetNextAlias() As Character

_cQuery := " SELECT  SUM(CP.CP_QUANT - CP.CP_QUJE) QUANT "
_cQuery += " FROM " + RetSqlName("SCP") + " CP "
_cQuery += " WHERE CP.D_E_L_E_T_ = ' ' "
_cQuery += " AND CP.CP_STATUS = ' ' "
_cQuery += " AND CP.CP_FILIAL = '"+xFilial("SCP")+"' " 
_cQuery += " AND CP.CP_PRODUTO = '"+_cProd+"' "
_cQuery += " AND CP.CP_LOCAL = '"+_cArmz+"' "
_cQuery += " AND CP.CP_NUM <> '"+_cNumSA+"' "
_cQuery += " AND CP.CP_PREREQU = ' ' " 

MPSysOpenQuery( _cQuery,_cAliasSCP )

DBSelectArea(_cAliasSCP)
If (_cAliasSCP)->(!Eof())
   _nQtd := (_cAliasSCP)->QUANT	
EndIf

(_cAliasSCP)->(DBCloseArea())

Return _nQtd

/*
===============================================================================================================================
Programa----------: Vldinves
Autor-------------: Josué Danich Prestes
Data da Criacao---: 13/10/2015 
Descrição---------: Valida se campo Local de investimento é editável ou não
Parametros--------: Nenhum	
Retorno-----------:  _lRet - campo editável ou não
===============================================================================================================================
*/
User Function vldinves() As Logical

Local _lRet := .T. As Logical

If acols[n][aScan(aHeader , {|X| Upper( AllTrim( X[2] ) ) == "CP_I_INVES"     } )] <> "S"
  _lRet := .F.
EndIf

Return _lRet

/*
===============================================================================================================================
Programa----------: Vldcc
Autor-------------: Josué Danich Prestes
Data da Criacao---: 13/10/2015 
Descrição---------: Retorna centro de custo da filial
Parametros--------: 	
Retorno-----------:  _cCC - centro de custo da filial
===============================================================================================================================
*/
User Function vldcc() As Character

Local _cCC := SuperGetMV("IT_CCFIL",.F.,"18001001") As Character

Return _cCC
