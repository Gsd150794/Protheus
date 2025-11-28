/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |17/09/2019| Retirada chamada da função itputx1. Chamado 28346 
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RPON012
Autor-------------: Julio de Paula Paz
Data da Criacao---: 07/08/2018                            .
Descrição---------: Relatório de Crachas. Chamado 25734.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RPON012()

Local _oReport := nil
Private _aOrder := {"Filial","Matricula","Nr.Crachá"}
Private _oSect1_A := Nil

Private _nOrdReport := 1
	
// Gera a pergunta de modo oculto, ficando disponível no botão ações relacionadas
Pergunte("RPON012",.F.)	          

// Chama a montagem do relatório.
_oReport := RPON012D("RPON012")
_oReport:PrintDialog()
	
Return

/*
===============================================================================================================================
Programa----------: RPON012D
Autor-------------: Julio de Paula Paz
Data da Criacao---: 07/08/2018
Descrição---------: Realiza as definições do relatório. (ReportDef)
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RPON012D(_cNome)
Local _oReport := Nil

Begin Sequence	
   _oReport := TReport():New(_cNome,"Relatório de Crachas",_cNome,{|_oReport| RPON012P(_oReport)},"Emissão do Relatório de Crachas")
   _oReport:SetLandscape()    
   _oReport:SetTotalInLine(.F.)

   // Define as totalizações e quebra por seção.
   //TRFunction():New(oSection2:Cell("B1_COD"),NIL,"COUNT",,,,,.F.,.T.)
   _oReport:SetTotalInLine(.F.)
   
   // "Data de emissão 
   _oSect1_A := TRSection():New(_oReport , "Relatório de Crachas" , {},_aOrder , .F., .T.)
   TRCell():New(_oSect1_A,"CODIEMPR"	 , "TRBPTO"  ,"Filial","@!",06)
   TRCell():New(_oSect1_A,"DESCFILIAL"	 , "TRBPTO"  ,"Nome Filial","@!",20)
   TRCell():New(_oSect1_A,"ICARD"	     , "TRBPTO"  ,"Id Cracha","@!",14)
   TRCell():New(_oSect1_A,"CODIMATR"	 , "TRBPTO"  ,"Matricula","@!",14)
   TRCell():New(_oSect1_A,"IDCOLAB"	     , "TRBPTO"  ,"ID Colaborador","@!",15)		
   TRCell():New(_oSect1_A,"NOMEPESS"	 , "TRBPTO"  ,"Nome Colaborador","@!",50)		
   TRCell():New(_oSect1_A,"DESCTIPOCOLA" , "TRBPTO"  ,"Tipo Colaborador","@!",20)		
   TRCell():New(_oSect1_A,"DATAINIC" 	 , "TRBPTO"  ,"Data Inicial","@!",12)		
   TRCell():New(_oSect1_A,"HORAINIC"	 , "TRBPTO"  ,"Hora Inicial","@!",12)		
   TRCell():New(_oSect1_A,"DATAFINA"	 , "TRBPTO"  ,"Data Final","@!",10)		
   TRCell():New(_oSect1_A,"HORAFINA"	 , "TRBPTO"  ,"Hora Final","@!",10)		
   TRCell():New(_oSect1_A,"SITUACAO"     , "TRBPTO"  ,"Situação","@!",20)		
   _oSect1_A:SetTotalText(" ")
   _oSect1_A:Disable()

End Sequence
					
Return(_oReport)

/*
===============================================================================================================================
Programa----------: RPON012P
Autor-------------: Julio de Paula Paz
Data da Criacao---: 07/08/2018
Descrição---------: Realiza a impressão do relatório. (ReportPrint)
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RPON012P(_oReport)
Local _cQry   := ""		
Local _cOrder := ""
Local _cSituacao := ""
Local _nI, _aFiliais := FwLoadSM0()
Local _cCodFil, _cDescFilial
Local _nCodMatr

Begin Sequence                    
   // Ativa a seção do relatório conforme a ordem de emissão do relatório.
   _nOrdReport := _oReport:GetOrder()

   If _nOrdReport == 1 // Filial
      _cOrder := " ORDER BY C.CODIEMPR "
   ElseIf _nOrdReport == 2 // Matricula
      _cOrder := " ORDER BY C.CODIMATR "
   Else // Nr.Crachá   
      _cOrder := " ORDER BY A.NUMECRAC "
   EndIf
   _oSect1_A:Enable() 
      
   // Monta a query de dados.
   _cQry := " SELECT A.ICARD, A.NUMECRAC, B.IDCOLAB, E.NOMEPESS, D.DESCTIPOCOLA, B.DATAINIC, B.HORAINIC, B.DATAFINA, B.HORAFINA, C.CODIMATR, C.CODIEMPR "
   _cQry += " FROM suricato.TBCADASCRACH A RIGHT OUTER JOIN suricato.TBHISTOCRACH B ON A.ICARD = B.ICARD "
   _cQry += " JOIN suricato.TBCOLAB C ON C.IDCOLAB = B.IDCOLAB "
   _cQry += " JOIN suricato.TBTIPOCOLAB D ON D.TIPOCOLA = C.TIPOCOLA "
   _cQry += " JOIN suricato.TBPESSOA E ON E.IDPESSOA = C.IDPESSOA "
   _cQry += " WHERE B.STATHIST = 1 "

   If ! Empty(MV_PAR04) //  Numero Cracha
      _cQry += " AND A.ICARD = '"+AllTrim(MV_PAR04)+"' "
   EndIf
   
   If MV_PAR05  == 1 // Situação do Crachá = Ativo
      _cQry += " AND ((B.DATAFINA < to_date('"+DToC(Date())+"','DD/MM/YY') AND B.HORAFINA = 0)) OR (B.DATAFINA > to_date('"+DToC(Date())+"','DD/MM/YY')) "
   ElseIf MV_PAR05  == 2 // Baixados  
      _cQry += " AND B.DATAFINA < to_date('"+DToC(Date())+"','DD/MM/YY') AND B.HORAFINA > 0 "
   EndIf
   
   _cQry := _cQry + _cOrder
   
   If Select("TRBPTO") <> 0
	  TRBPTO->(DBCloseArea())
   EndIf
	
   DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQry) , "TRBPTO" , .T. , .F. )
   	
   DBSelectArea("TRBPTO")
   TRBPTO->(DBGoTop())

   Count to _ntotRegs	
   _oReport:SetMeter(_ntotRegs)	
   
   // Inicializando a primeira seção
   _oSect1_A:Init()
   
   // Inicia processo de impressão.
   TRBPTO->(DBGoTop())
   
   While !TRBPTO->(Eof())
		
      If _oReport:Cancel()
		 Exit
      EndIf
      
      _cCodFil := StrZero(TRBPTO->CODIEMPR,2)
      
      // Filtro por filial
      If ! Empty(MV_PAR01) // Nome Colaborador
         If ! _cCodFil $ MV_PAR01
            TRBPTO->(DBSkip())
            Loop
         EndIf
      EndIf

      // Filtro por código de matricula
      If !Empty(MV_PAR02)  // Matricula de
         _nCodMatr := Val(RPON012M(MV_PAR02))
         If TRBPTO->CODIMATR < _nCodMatr
            TRBPTO->(DBSkip())
            Loop 
         EndIf
         //_cQry +=  " AND C.CODIMATR >= " + RPON012M(MV_PAR02)+" "
      EndIf

      If ! Empty(MV_PAR03) // Matricula ate
         _nCodMatr := Val(RPON012M(MV_PAR03))
         If TRBPTO->CODIMATR > _nCodMatr
            TRBPTO->(DBSkip())
            Loop 
         EndIf
      EndIf

      // Grava e imprime os dados do relatório.
	  _oReport:IncMeter()
	  
	  //_cCodFil := StrZero(TRBPTO->CODIEMPR,2)
	  
	  _nI := aScan(_aFiliais,{|x| x[5] == _cCodFil})
	  If _nI > 0 
	     _cDescFilial := _aFiliais[_nI,7]
	  Else
	     _cDescFilial := "" 
	  EndIf
	  
	  _oSect1_A:Cell("CODIEMPR")    :SetValue(_cCodFil)         // Filial
	  _oSect1_A:Cell("CODIEMPR")    :SetAlign("LEFT")
	  
	  _oSect1_A:Cell("DESCFILIAL")  :SetValue(_cDescFilial)         // Nome da Filial
	  _oSect1_A:Cell("DESCFILIAL")  :SetAlign("LEFT")
	  	  
	  _oSect1_A:Cell("ICARD")       :SetValue(TRBPTO->ICARD)        // Id Cracha
	  _oSect1_A:Cell("ICARD")       :SetAlign("LEFT")
	  
      _oSect1_A:Cell("CODIMATR")    :SetValue(TRBPTO->CODIMATR)     // Numero Cracha
      _oSect1_A:Cell("CODIMATR")    :SetAlign("LEFT")
      
      _oSect1_A:Cell("IDCOLAB")     :SetValue(TRBPTO->IDCOLAB)      // ID Colaborador
      _oSect1_A:Cell("IDCOLAB")     :SetAlign("LEFT")
      
      _oSect1_A:Cell("NOMEPESS")    :SetValue(TRBPTO->NOMEPESS)     // Nome Colaborador
      _oSect1_A:Cell("NOMEPESS")    :SetAlign("LEFT")
      
      _oSect1_A:Cell("DESCTIPOCOLA"):SetValue(TRBPTO->DESCTIPOCOLA) // Tipo Colaborador
      _oSect1_A:Cell("DESCTIPOCOLA"):SetAlign("LEFT")
      
      _oSect1_A:Cell("DATAINIC")    :SetValue(TRBPTO->DATAINIC)     // data Inicial
      _oSect1_A:Cell("DATAINIC")    :SetAlign("CENTER")
      
      _oSect1_A:Cell("HORAINIC")    :SetValue(RPON012L(TRBPTO->HORAINIC))     // hora inicial
      _oSect1_A:Cell("HORAINIC")    :SetAlign("CENTER")
      
      If Year(TRBPTO->DATAFINA) == 1900 
         _oSect1_A:Cell("DATAFINA") :SetValue("")                  // data final
         _oSect1_A:Cell("HORAFINA") :SetValue("")                  // hora final
      Else
         _oSect1_A:Cell("DATAFINA") :SetValue(TRBPTO->DATAFINA)    // data final
         _oSect1_A:Cell("DATAFINA") :SetAlign("CENTER")
         _oSect1_A:Cell("HORAFINA") :SetValue(RPON012L(TRBPTO->HORAFINA))    // hora final
         _oSect1_A:Cell("HORAFINA") :SetAlign("CENTER")
      EndIf
      
      // Situação do Crachá 
      If (DToS(TRBPTO->DATAFINA) < DToS(Date()) .And. TRBPTO->HORAFINA == 0) .Or. (DToS(TRBPTO->DATAFINA) > DToS(Date())) // Ativo       
         _cSituacao := "ATIVO"
      ElseIf DToS(TRBPTO->DATAFINA) <= DToS(Date()) .And. TRBPTO->HORAFINA > 0 // Baixados  
         _cSituacao := "BAIXADO" 
      Else
         _cSituacao := "INATIVOS" 
      EndIf
      
      _oSect1_A:Cell("SITUACAO"):SetValue(_cSituacao)    // Situação
	  
	  _oSect1_A:PrintLine()
         
      TRBPTO->(DBSkip())
   EndDo		
      
   // Imprime linha separadora.
   _oReport:ThinLine()
   
   // Finaliza primeira seção.
   _oSect1_A:Finish()
End Sequence

Return

/*
===============================================================================================================================
Programa----------: RPON012L
Autor-------------: Julio de Paula Paz
Data da Criacao---: 10/08/2018
Descrição---------: Converte e retorna um tempo em minutos passados como parâmetro no formato hora e minutos (hh:mm).
Parametros--------: _nTempo = Temmpo em minutos
Retorno-----------: _cRet = tempo em minutos convertido para o formato hh:mm
===============================================================================================================================
*/
Static Function RPON012L(_nTempo)
Local _cRet := ""
Local _cHoras, _cMinutos

Begin Sequence
   If _nTempo == 0
      _cRet := "00:00"
      Break
   EndIf

   _cHoras := Int(_nTempo / 60)
   
   _cMinutos := Mod( _nTempo, 60)

   _cRet := StrZero(_cHoras,2)+":"+StrZero(_cMinutos,2)
   
End Sequence

Return _cRet

/*
===============================================================================================================================
Programa----------: RPON012M
Autor-------------: Julio de Paula Paz
Data da Criacao---: 15/08/2018
Descrição---------: Verifica se o conteúdo de um campo é numerico.
Parametros--------: _cDado = Dado a ser verificado.
Retorno-----------: _cRet = " " se o parêmtro estiver vazio,
                    _cRet = _cDado se o dado estiver preenchido e For numerico.
                    _cRet = "9999999' se existir letras em _cDado.
===============================================================================================================================
*/
Static Function RPON012M(_cDado)
Local _cRet := "0"
Local _nI, _cDigito

Begin Sequence
   If Empty(_cDado)
      Break
   EndIf
   
   _cDado := AllTrim(_cDado)
   _cRet := _cDado
   
   For _nI := 1 To Len(_cDado)
       _cDigito := SubStr(_cDado,_nI,1)
       If ! (_cDigito $ "0123456789")
          _cRet := "999999999999"
          Break
       EndIf
   Next
   
End Sequence

Return _cRet
