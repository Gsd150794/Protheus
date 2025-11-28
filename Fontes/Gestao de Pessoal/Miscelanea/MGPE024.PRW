/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |30/11/2023| Chamado 45610 - Incluido os campos Descrição da Função e Descricao do Departamento.
Alex Wallauer |12/08/2024| Chamado 47047 - Retirado os IFs de Teste de PRODUCAO.
Lucas Borges  |23/07/2025| Chamado 51340. Ajustar função para validação de ambiente de teste
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MGPE024
Autor-------------: Igor Melgaço
Data da Criacao---: 02/03/2023
Descrição---------: Workflow de Relação de Funcionários com Horas extras. Chamado 43000
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGPE024()
Local _lTela     := .T.
Local _cTimeIni  := Time()
Local _lRet      := .F.
Local _lMGPE024 

Begin Sequence
   
   //Testa se esta sendo rodado do menu
   If Select('SX3') == 0
        
      RPCSetType( 2 )	// Não consome licensa de uso
            
      RpcSetEnv('01','01',,,,GetEnvServer(),{ "SRA","SQB", "SRF" })
      Sleep( 5000 )					//Aguarda 5 segundos para que as jobs IPC subam.
            
      _lTela := .F.

   EndIf

   _lMGPE024  := U_ITGETMV( "IT_MGPE024" , .T.) // Parametro para ativar e desativar a rotina

   If _lMGPE024 // Executa ou não a rotina
      If _lTela
         FWMsgRun( ,{|oProc|  _lRet := MGPE024EM(oProc) } , "Hora Inicial: "+_cTimeIni+" Lendo Funcionários...")
      Else
         //Atualização tabela SM2
         U_ITConOut("INICIO DO PROCESSAMENTO - Hora Inicial: "+_cTimeIni)

         _lRet := MGPE024EM()

         U_ITConOut("FIM DO PROCESSAMENTO - Hora Final: "+TIME())

         RpcClearEnv() //Libera o Ambiente
      EndIf
   EndIf

End Sequence 

Return _lRet


/*
===============================================================================================================================
Programa----------: MGPE024EM
Autor-------------: Igor Melgaço
Data da Criacao---: 02/03/2023
Descrição---------: Rotina de envio do email
Parametros--------: oProc = objeto da barra de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGPE024EM(oProc)
Local _aConfig	 := {}
Local _cEmlLog	 := ""
Local _cMsgEml	 := ""
Local _aCab      := {}
Local _aSizes    := {}
Local _aRet      := {}
Local _cGetCc	 := ""
Local _cGetPara	 := ""
Local _cGetAssun  := "Controle de Horas Extras de Funcionários "
Local _cTit      := " "
Local _nCont     := 0
Local _aResp     := {}
Local cTGetPara  := ""
Local _dData1    := Date()-7
Local _dData2    := Date()-6
Local _dData3    := Date()-5
Local _dData4    := Date()-4
Local _dData5    := Date()-3
Local _dData6    := Date()-2
Local _dData7    := Date()-1
Local _cEmail    := U_ItGetMV("IT_MG24","01")
Local _aFiliais  := {}
Local _cFilBkp   := ""
Local _n         := 0

_cFilBkp := cFilAnt
DBSelectArea("SM0")
SM0->(DBGoTop())
While !SM0->(Eof())
    cFilAnt := SM0->M0_CODFIL
    _cEmail := U_ItGetMV("IT_EMMG24","")
    If !Empty(AllTrim(_cEmail))
        aAdd(_aFiliais,{cFilAnt,_cEmail})
    EndIf
    SM0->(DBSkip())
EndDo
cFilAnt := _cFilBkp

_aSizes := {"05"       ,"25"  ,"05"          ,"05"          ,"05"          ,"05"           ,"05"         ,"05"          ,"05"           ,"10"    }
_aAling := {"center"   ,"left","center"      ,"center"      ,"center"      ,"center"       ,"center"     ,"center"      ,"center"       ,"center"}
_aCab   := {"Matricula","Nome", DToC(_dData1), DToC(_dData2), DToC(_dData3), DToC(_dData4), DToC(_dData5), DToC(_dData6), DToC(_dData7) , "Total de Hrs" } 
_aCabDt := {(_dData1), (_dData2), (_dData3), (_dData4), (_dData5), (_dData6), (_dData7)} 

If oProc <> Nil
	oProc:cCaption := ("Lendo dados do periodo...")
	ProcessMessages()
EndIf

_aRet     := MGPE024BRO() // 
_aResp    := _aRet[1]
_aFilResp := _aRet[2]

If Len(_aResp) = 0 
    If oProc <> Nil
        U_ITMsg("Não há dados no periodo.","Envio do E-MAIL",,3)
    Else
        U_ITConOut("Não há dados no periodo.")
    EndIf
Else
    _aConfig := U_ITCFGEML('')
//********************************** ENVIA OS EMAILS POR RESPONSÁVEL ******************************************
    For _nCont := 1 to Len(_aResp)

        _cTit     := "Filial: " + _aResp[_nCont][1]  +" - "+ FWFilialName( cEmpAnt ,  _aResp[_nCont][1], 2 )
        _cTit2    := "Responsável: " + _aResp[_nCont][2] + " - " + _aResp[_nCont][3] + " - E-mail: " + _aResp[_nCont][4] 
        _cAssuRes := _cGetAssun + " - "+"Responsável: " + _aResp[_nCont][2] + " - " + _aResp[_nCont][3]
        _cGetPara :=  AllTrim(_aResp[_nCont][4] )
        _cGetCC   := "" //_aResp[_nCont][5]

        If !LOWER(_cGetPara) $ cTGetPara .And. !Empty(_cGetPara)
           cTGetPara += If(Empty(AllTrim(cTGetPara)),"",CHR(13)+CHR(10)) + AllTrim(_aResp[_nCont][3]) +" - " + LOWER( _cGetPara )
        EndIf
        
        _cMsgEml  := MGPE024EML(_aResp[_nCont][1] ,_aResp[_nCont][2] ,_aResp[_nCont][3],_cTit,_cGetAssun,_aSizes,_aCab,oProc,_cTit2)

        If oProc <> Nil
            oProc:cCaption := ("Enviando o e-mail p/ "+SubStr(_cTit2,1,AT(" - E-mail:",_cTit2)))
            ProcessMessages()
        EndIf
        
        // Chama a função para envio do e-mail
        //ITEnvMail(cFrom       ,cEmailTo  ,_cEmailCo ,cEmailBcc,cAssunto ,cMensagem,cAttach   ,cAccount    ,cPassword   ,cServer     ,cPortCon    ,lRelauth     ,cUserAut     ,cPassAut     ,cLogErro)
        U_ITENVMAIL(_aConfig[01], _cGetPara,   _cGetCc,       "",_cAssuRes, _cMsgEml,        "",_aConfig[01], _aConfig[02],_aConfig[03],_aConfig[04],_aConfig[05],_aConfig[06],_aConfig[07], @_cEmlLog )

    
    Next

    _aConfig := U_ITCFGEML('')
//********************************** ENVIA OS EMAILS POR UNIDADE ***********************************************************
    For _nCont := 1 to Len(_aFilResp)
        _n := aScan(_aFiliais,{|x|x[1] == _aFilResp[_nCont]})
        If _n > 0
            _cTit     := "Filial: " + _aFilResp[_nCont] +" - "+ FWFilialName( cEmpAnt ,  _aFilResp[_nCont] , 2 )
            _cAssuRes := _cGetAssun + " - "+_cTit
            _cGetPara := _aFiliais[_n][2] 
            _cGetCC   := "" //_aResp[_nCont][5]
            _cNomeArq := NIL//Arquivo do Excel preenchido na função MGPE024QRY()
            _cMsgEml  := MGPE024EML(_aFilResp[_nCont] , , ,_cTit,_cGetAssun,_aSizes,_aCab,oProc,)

            If oProc <> Nil
                oProc:cCaption := ("Enviando o e-mail para "+_cTit)
                ProcessMessages()
            EndIf

            If !LOWER(_cGetPara) $ cTGetPara .And. !Empty(_cGetPara)
               cTGetPara += If(Empty(AllTrim(cTGetPara)),"",CHR(13)+CHR(10)) + "Filial "+_aFilResp[_nCont]  +" - " + LOWER( _cGetPara )
            EndIf

            // Chama a função para envio do e-mail
            //ITEnvMail(cFrom       ,cEmailTo  , _cEmailCo,cEmailBcc,cAssunto  ,cMensagem,cAttach  ,cAccount    ,cPassword    ,cServer     ,cPortCon    ,lRelauth    ,cUserAut    ,cPassAut    ,cLogErro)
            U_ITENVMAIL(_aConfig[01], _cGetPara,   _cGetCc,       "",_cAssuRes, _cMsgEml,_cNomeArq,_aConfig[01], _aConfig[02],_aConfig[03],_aConfig[04],_aConfig[05],_aConfig[06],_aConfig[07], @_cEmlLog )
            If _cNomeArq <> NIL .And. FErase(_cNomeArq)
               U_ITCONOUT("Arquivo "+_cNomeArq+" apagado com sucesso")
	        EndIf 
        EndIf
    Next

    If oProc <> Nil
        cTGetPara:= StrTran( cTGetPara, ";", " - ")
        bBloco:={|| U_ITMsgLog( cTGetPara , "E-MAILs") }
        U_ITMsg(Upper(_cEmlLog)+CHR(13)+CHR(10)+;
        "E-mail para: "+_cGetPara;//+;        " Com Copia: "+cTGetCc+CHR(13)+CHR(10)
        ,"Envio do E-MAIL",,3,,,,,,bBloco)
    Else
        U_ITConOut(Upper(_cEmlLog)+CHR(13)+CHR(10)+;
        "E-mail para: "+cTGetPara) //+;        " Com Copia: "+cTGetCc+CHR(13)+CHR(10))
    EndIf
EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: MGPE024BRO
Autor-------------: Igor Melgaço
Data da Criacao---: 02/03/2023
Descrição---------: Responsáveis pelos deptos aos quais serão enviado o email
Parametros--------: Nenhum
Retorno-----------: _aDados = Lista dos Responsáveis pelos deptos aos quais serão enviado o email
===============================================================================================================================
*/  
Static Function MGPE024BRO()
Local _cAliasQB   := ''
Local _cFiltro	  := ''
Local _aResp      := {}
Local _aFilResp   := {}

_cAliasQB := GetNextAlias()

_cFiltro += "% "
_cFiltro += " SPC.D_E_L_E_T_ = ' ' "
_cFiltro += " AND SPC.PC_DATA <= '" + DToS(Date()-1) + "'"
_cFiltro += " AND SPC.PC_DATA >= '" + DToS(Date()-4) + "'"
_cFiltro += " %"

BeginSql Alias _cAliasQB

    SELECT QB_FILRESP, QB_MATRESP, (SRA2.RA_NOME) AS QB_NOMRESP , (SRA2.RA_EMAIL) AS QB_EMRESP, SUM(SPC.PC_QUANTC) AS HORAS
    FROM %Table:SPC%  SPC 
        JOIN      %Table:SRA%  SRA  ON SRA.RA_FILIAL  = SPC.PC_FILIAL AND SRA.RA_MAT = SPC.PC_MAT     AND SRA.%notDel%
        LEFT JOIN %Table:SQB%  SQB  ON SRA.RA_DEPTO   = SQB.QB_DEPTO  AND RA_FILIAL  = QB_FILIAL      AND SQB.%notDel%
        JOIN      %Table:SRA%  SRA2 ON SQB.QB_MATRESP = SRA2.RA_MAT   AND QB_FILRESP = SRA2.RA_FILIAL AND SRA2.%notDel% 
        JOIN      %Table:SP9%  SP9  ON SP9.P9_FILIAL  = SPC.PC_FILIAL AND (SP9.P9_CODIGO = SPC.PC_PD  OR  SP9.P9_CODIGO = SPC.PC_PDI)
    WHERE %Exp:_cFiltro%
        AND SP9.P9_CLASEV = '01'
    GROUP BY QB_FILRESP, QB_MATRESP, SRA2.RA_NOME, SRA2.RA_EMAIL
    ORDER BY QB_FILRESP, QB_MATRESP

EndSql

DBSelectArea(_cAliasQB)
(_cAliasQB)->(DBGoTop())
If !(_cAliasQB)->(Eof())
	While !(_cAliasQB)->(Eof())
		aAdd(_aResp,{(_cAliasQB)->QB_FILRESP,;
                     (_cAliasQB)->QB_MATRESP,;
                     (_cAliasQB)->QB_NOMRESP,;
                     (_cAliasQB)->QB_EMRESP})

        If aScan(_aFilResp,{|x| x == (_cAliasQB)->QB_FILRESP}) = 0
            aAdd(_aFilResp,(_cAliasQB)->QB_FILRESP)
        EndIf

        (_cAliasQB)->(DBSkip())
	EndDo
	(_cAliasQB)->( DBCloseArea() )
EndIf

Return {_aResp,_aFilResp}

/*
===============================================================================================================================
Programa----------: MGPE024QRY
Autor-------------: Igor Melgaço
Data da Criacao---: 02/03/2023
Descrição---------: Gera a lista de Funcionários com horas extras
Parametros--------: _cFilialResp = Filial do responsável pelo Depto	
                    _cMatResp = Matricula do responsável pelo Depto	
Retorno-----------: _aDados = Array de Funcionarios 
===============================================================================================================================
*/  
Static Function MGPE024QRY(_cFilialResp,_cMatResp,oProc)
Local _cAliasSPC   := ''
Local _cFiltro	   := ''
Local _aDados      := {}
Local i := 0
Local _dData1      := CTOD("")
Local _dData2      := CTOD("")
Local _dData3      := CTOD("")
Local _dData4      := CTOD("")
Local _dData5      := CTOD("")
Local _dData6      := CTOD("")
Local _dData7      := CTOD("")
Local _nVrData1    := 0
Local _nVrData2    := 0
Local _nVrData3    := 0
Local _nVrData4    := 0
Local _nVrData5    := 0
Local _nVrData6    := 0
Local _nVrData7    := 0

Local _cMatAntes   := ""
Local _cNomeAntes  := ""
Local _cRespoAntes := ""
Local _cDeptoAntes := ""
Local _cFunctAntes := ""

Default _cMatResp  := ""

_dData1      := Date()-7
_dData2      := Date()-6
_dData3      := Date()-5
_dData4      := Date()-4
_dData5      := Date()-3
_dData6      := Date()-2
_dData7      := Date()-1

_cAliasSPC := GetNextAlias()

_cFiltro += "% "
_cFiltro += " SPC.D_E_L_E_T_ = ' ' "
_cFiltro += " AND SPC.PC_DATA <= '" + DToS(Date()-1) + "'"
_cFiltro += " AND SPC.PC_DATA >= '" + DToS(Date()-7) + "'"
_cFiltro += " AND QB_FILRESP = '"+_cFilialResp+"' "

If !Empty(AllTrim(_cMatResp))
    _cFiltro += " AND QB_MATRESP = '"+_cMatResp+"' "
EndIf

_cFiltro += " %"

BeginSql Alias _cAliasSPC

    SELECT   QB_DEPTO, SRA.RA_FILIAL, SRA.RA_MAT, SRA.RA_NOME , SRA.RA_EMAIL, SRA.RA_DEPTO, SRA.RA_CODFUNC, SPC.PC_DATA, QB_MATRESP, SUM(SPC.PC_QUANTC) AS HORAS
    FROM %Table:SPC%  SPC 
        JOIN      %Table:SRA%  SRA  ON SRA.RA_FILIAL  = SPC.PC_FILIAL AND SRA.RA_MAT    = SPC.PC_MAT AND SRA.%notDel%
        LEFT JOIN %Table:SQB%  SQB  ON SRA.RA_DEPTO   = SQB.QB_DEPTO  AND RA_FILIAL     = QB_FILIAL  AND SQB.%notDel% //JOIN      %Table:SRA%  SRA2 ON SQB.QB_MATRESP = SRA2.RA_MAT   AND QB_FILRESP = SRA2.RA_FILIAL AND SRA2.%notDel%
        JOIN      %Table:SP9%  SP9  ON SP9.P9_FILIAL  = SPC.PC_FILIAL AND SP9.P9_CODIGO = SPC.PC_PD 
    WHERE %Exp:_cFiltro%
        AND SP9.P9_CLASEV = '01'
    GROUP BY QB_DEPTO, SRA.RA_FILIAL, SRA.RA_MAT, SRA.RA_NOME , SRA.RA_EMAIL, SRA.RA_DEPTO, SRA.RA_CODFUNC, SPC.PC_DATA, QB_MATRESP
    ORDER BY SRA.RA_MAT

EndSql
_aExcel:={}
DBSelectArea(_cAliasSPC)
(_cAliasSPC)->(DBGoTop())
If !(_cAliasSPC)->(Eof())
    _cMatAntes := (_cAliasSPC)->RA_MAT
	While !(_cAliasSPC)->(Eof())

        If _cMatAntes <> (_cAliasSPC)->RA_MAT 

            aAdd(_aDados,{_cMatAntes,;
                          _cNomeAntes,;  
                          Transform( _nVrData1 ,"@E 999,999.99") ,;
                          Transform( _nVrData2 ,"@E 999,999.99") ,;
                          Transform( _nVrData3 ,"@E 999,999.99") ,;
                          Transform( _nVrData4 ,"@E 999,999.99") ,;
                          Transform( _nVrData5 ,"@E 999,999.99") ,;
                          Transform( _nVrData6 ,"@E 999,999.99") ,;
                          Transform( _nVrData7 ,"@E 999,999.99") ,;
                          Transform( _nVrData1+_nVrData2+_nVrData3+_nVrData4+_nVrData5+_nVrData6+_nVrData7 ,"@E 999,999.99") })

            aAdd(_aExcel,{_cMatAntes  ,;
                          _cNomeAntes ,;  
                          _cDeptoAntes,;  
                          _cFunctAntes,;  
                          _cRespoAntes ,;  
                          _nVrData1   ,;
                          _nVrData2   ,;
                          _nVrData3   ,;
                          _nVrData4   ,;
                          _nVrData5   ,;
                          _nVrData6   ,;
                          _nVrData7   ,;
                          _nVrData1+_nVrData2+_nVrData3+_nVrData4+_nVrData5+_nVrData6+_nVrData7 })


            _nVrData1 := _nVrData2 := _nVrData3 := _nVrData4 := _nVrData5 := _nVrData6 := _nVrData7 := 0
        EndIf
            
        For i := 1 To 7
            If (_cAliasSPC)->PC_DATA == DToS(&("_dData"+AllTrim(Str(i))))
                &("_nVrData"+AllTrim(Str(i))) := (_cAliasSPC)->HORAS
            EndIf
        Next
            
        _cMatAntes  := (_cAliasSPC)->RA_MAT
        _cDeptoAntes:= AllTrim(Posicione("SQB",1,(_cAliasSPC)->RA_FILIAL + (_cAliasSPC)->RA_DEPTO  ,"QB_DESCRIC"))
        _cRespoAntes:= AllTrim(Posicione("SRA",1,(_cAliasSPC)->RA_FILIAL + (_cAliasSPC)->QB_MATRESP,"RA_NOME"))
        _cFunctAntes:= AllTrim(Posicione('SRJ',1,(_cAliasSPC)->RA_FILIAL + (_cAliasSPC)->RA_CODFUNC,'RJ_DESC'   ))
        _cNomeAntes := AllTrim((_cAliasSPC)->RA_NOME)// +" - "+ _cFunctAntes

		(_cAliasSPC)->(DBSkip())
	EndDo
    
    aAdd(_aDados,{_cMatAntes,;
                  _cNomeAntes ,;  
                  Transform( _nVrData1 ,"@E 999,999.99") ,;
                  Transform( _nVrData2 ,"@E 999,999.99") ,;
                  Transform( _nVrData3 ,"@E 999,999.99") ,;
                  Transform( _nVrData4 ,"@E 999,999.99") ,;
                  Transform( _nVrData5 ,"@E 999,999.99") ,;
                  Transform( _nVrData6 ,"@E 999,999.99") ,;
                  Transform( _nVrData7 ,"@E 999,999.99") ,;
                  Transform( _nVrData1+_nVrData2+_nVrData3+_nVrData4+_nVrData5+_nVrData6+_nVrData7 ,"@E 999,999.99") })

    aAdd(_aExcel,{_cMatAntes  ,;
                  _cNomeAntes ,;  
                  _cDeptoAntes,;  
                  _cFunctAntes,;  
                  _cRespoAntes,;  
                  _nVrData1   ,;
                  _nVrData2   ,;
                  _nVrData3   ,;
                  _nVrData4   ,;
                  _nVrData5   ,;
                  _nVrData6   ,;
                  _nVrData7   ,;
                  _nVrData1+_nVrData2+_nVrData3+_nVrData4+_nVrData5+_nVrData6+_nVrData7 })

	(_cAliasSPC)->( DBCloseArea() )
EndIf

If Empty(AllTrim(_cMatResp)) .And. Len(_aExcel) > 0 //************* GERA O ARQUIVO DO EXCEL SÓ QUANDO É POR FILIAL ********************************

   If oProc <> NIL
      oProc:cCaption := ("Gerando Excel da Filial: "+_cFilialResp )
      ProcessMessages()
   EndIf
   _cDataHora := "_Dt_" + StrZero(Day(Date()),2) + "_" + StrZero(Month(Date()),2) + "_" + StrZero(Year(Date()),4) + "_Hr_" + StrTran(Time(),":","_")
   _cNomeArq  := "SEMANAL_HE" +  _cDataHora + ".xlsx"//XLSX
   _cTitulo   := "Relatório Semanal de Horas Extras" 
   _cPathSrv  := AllTrim(GETMV("MV_RELT",,"\SPOOL\"))
   
   _aCabec := {} // Array com o cabeçalho das colunas do relatório. 
   // Alinhamento( 1-Left,2-Center,3-Right )
   // Formatação( 1-General,2-Number,3-Monetário,4-DateTime )
   //                  Titulo das Colunas ,Alinhamento ,Formatação, Totaliza? 
   aAdd(_aCabec,{"Matricula"              ,2           ,1         ,.F.})    
   aAdd(_aCabec,{"Nome do Funcionario"    ,1           ,1         ,.F.})     
   aAdd(_aCabec,{"Departamento"           ,1           ,1         ,.F.})    
   aAdd(_aCabec,{"Função do Funcionario"  ,1           ,1         ,.F.})    
   aAdd(_aCabec,{"Responsavel"            ,1           ,1         ,.F.})    
   aAdd(_aCabec,{_aCabDt[1]               ,3           ,2         ,.F.})    
   aAdd(_aCabec,{_aCabDt[2]               ,3           ,2         ,.F.})    
   aAdd(_aCabec,{_aCabDt[3]               ,3           ,2         ,.F.})    
   aAdd(_aCabec,{_aCabDt[4]               ,3           ,2         ,.F.})    
   aAdd(_aCabec,{_aCabDt[5]               ,3           ,2         ,.F.})    
   aAdd(_aCabec,{_aCabDt[6]               ,3           ,2         ,.F.})    
   aAdd(_aCabec,{_aCabDt[7]               ,3           ,2         ,.F.})    
   aAdd(_aCabec,{"Total de Horas"         ,3           ,2         ,.F.})     
   
   aSort( _aExcel ,,, {|X, Y| X[3]+X[5]+X[2] < Y[3]+Y[5]+Y[2] } )

   //ITGEREXCEL(_cNomeArq,_cDiretorio,_cTitulo,_cNomePlan,_aCabecalho,_aDetalhe,_lLeTabTemp,_cAliasTab,_aCampos,_lScheduller,_lCriaPastas,_aPergunte,_lEnviaEmail,_lXLSX)
   U_ITGEREXCEL(_cNomeArq,_cPathSrv  ,_cTitulo,          ,_aCabec    ,_aExcel  ,           ,          ,        , .T.        ,            ,          , .T.        ,.T.   ) 
   _cNomeArq:=_cPathSrv+_cNomeArq

   If File(_cNomeArq) .And. U_AOMS097F(_cNomeArq)
      U_ItConOut("Arquivo: " + _cNomeArq + ", gerado com sucesso!" )
   Else
      U_ItConOut("Falha na Geração do Arquivo: " + _cNomeArq + "." )
      _cNomeArq:=NIL
   EndIf

EndIf

Return _aDados

/*
===============================================================================================================================
Programa----------: MGPE024EML
Autor-------------: Igor Melgaço
Data da Criacao---: 19/07/2023
Descrição---------: Montagem do corpo do email
Parametros--------: _cFilialResp,_cMatResp,_cNomeResp,_cTit,_cGetAssun,_aSizes,_aCab,oProc,_cTit2
Retorno-----------: _cMsgEml = Conteudo Html para envio da Msg
===============================================================================================================================
*/  
Static Function MGPE024EML(_cFilialResp,_cMatResp,_cNomeResp,_cTit,_cGetAssun,_aSizes,_aCab,oProc,_cTit2)
Local _cMsgEml    := ""
Local _aFunc      := {}
Local _nFunc      := 0
Local _nTotalTit  := 0
Local _cGetLista  := ""
Local _nCol       := 0
Local _nLin       := 0

Default _cMatResp := ""
Default _cNomeResp := ""
Default oProc := NIL

    //Logo Italac
    _cMsgEml := '<html>'
    _cMsgEml += '<head><title>'+_cTit+'</title></head>'
    _cMsgEml += '<body>'
    _cMsgEml += '<style Type="text/css"><!--'
    _cMsgEml += 'table.bordasimples { border-collapse: collapse; }'
    _cMsgEml += 'table.bordasimples tr td { border:1px solid #777777; }'
    _cMsgEml += 'td.titulos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #C6E2FF; }'
    _cMsgEml += 'td.grupos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #E5E5E5; }'
    _cMsgEml += 'td.itens	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #FFFFFF; }'
    _cMsgEml += '--></style>'
    _cMsgEml += '<center>'
    _cMsgEml += '<img src="http://www.italac.com.br/wf/italac-wf.jpg" width="600" height="50"><br>'
    _cMsgEml += '<br>'
    _cMsgEml += '<table class="bordasimples" width="600">'
    _cMsgEml += '    <tr>'
    _cMsgEml += '	     <td class="titulos"><center>'+_cTit+'</center></td>'
    _cMsgEml += '	 </tr>'
    If !Empty(_cTit2)
       _cMsgEml += ' <tr>'
       _cMsgEml += '     <td class="titulos"><center>'+_cTit2+'</center></td>'
       _cMsgEml += ' </tr>'
    EndIf
    _cMsgEml += '</table>'
    _cMsgEml += '<br>'


    _cMsgEml += '</center>'
    _cMsgEml += '<br>'
    _cMsgEml += '<br>'
    _cMsgEml += '    <tr>'
    _cMsgEml += '      <td class="itens" align="left" > Caro(a), '+ AllTrim(_cNomeResp) +' <b></b></td>'
    _cMsgEml += '    </tr>'
    _cMsgEml += '<br>'

    _cMsgEml += '    <tr>'            
    _cMsgEml += '      <td class="itens" align="left" > Abaixo a listagem de horas extras por funcionario ! <b></b></td>'
    _cMsgEml += '    </tr>'
    _cMsgEml += '<br>'
    If oProc <> Nil
       DEFAULT _cTit2 := _cTit
       oProc:cCaption := ("Lendo dados "+SubStr(_cTit2,1,AT(" - E-mail:",_cTit2)))
       ProcessMessages()
    EndIf
    _aExcel     := {}
    _cNomeArq   := NIL
    _aFunc      := MGPE024QRY(_cFilialResp,_cMatResp,oProc)
    _nFunc      := Len(_aFunc)
    _nTotalTit  := 0
    _cGetLista  := ""

    If _nFunc > 0
        //Cabeçalho
        _cMsgEml += '<br>'
        _cMsgEml += '<table class="bordasimples" width="1300">'
        _cMsgEml += '    <tr>'
        _cMsgEml += '		<td align="center" colspan="'+AllTrim(Str(Len(_aSizes)))+'" class="grupos"><b>'+_cGetAssun+'</b></td>'
        _cMsgEml += '    </tr>'
        _cMsgEml += '    <tr>'

        For _nCol :=  1 To 10
            _cMsgEml += '      <td class="itens" align='+_aAling[_nCol]+' width="'+_aSizes[_nCol]+'%"><b>'+_aCab[_nCol]+'</b></td>'
        Next
        
        _cMsgEml += '    </tr>'
        _cMsgEml += '    #LISTA#'
        _cMsgEml += '</table>'

        For _nLin := 1 To _nFunc
            
            _cGetLista += '    <tr>'
            For _nCol :=  1 To 10
                _cGetLista += ' <td class="itens" align='+_aAling[_nCol]+' width="'+_aSizes[_nCol]+'%">'+ _aFunc[_nLin][_nCol] +'</td>' 
            Next
            _cGetLista += '    </tr>'
            
        Next
        
        _cMsgEml := StrTran(_cMsgEml,"#LISTA#",_cGetLista)

    EndIf

    _cMsgEml += '</center>'
    _cMsgEml += '<br>'
    _cMsgEml += '<br>'
    _cMsgEml += '    <tr>'
    _cMsgEml += '      <td class="itens" align="center" ><b>Ambiente:</b></td>'
    _cMsgEml += '      <td class="itens" align="left" > ['+ GETENVSERVER() +'] / <b>Fonte:</b> [MGPE024]</td>'
    _cMsgEml += '    </tr>'
    _cMsgEml += '</body>'
    _cMsgEml += '</html>'

Return _cMsgEml
