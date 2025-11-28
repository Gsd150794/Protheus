/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
 Autor        | Data     |                              Motivo                      										 
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |11/04/2025| Chamado 50448. Incluída validação para registros alterados após primeira integração.
Lucas Borges  |15/07/2025| Chamado 51354. Corrgida gravação da data e hora contemplando 4 dígitos no ano
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MGLT031
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 24/03/2025
Descrição---------: Rotina de integração WebService App da Qualidade e Gestão do Leite Protheus. Chamado 48203.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGLT031

Local _oSelf as Object

//============================================
//Cria interface principal
//============================================
tNewProcess():New(	"MGLT031"							/*cFunction*/	,; //Função inicial
					"Integra App Qualidade"				/*cTitle*/		,; //Descrição da Rotina
					{|_oSelf| MGLT031P(_oSelf) }		/*bProcess*/	,; //Função do processamento
					"Rotina para realizar a integração com o app da Qualidade e buscar as informações das"+;
					" análises de qualidade"/*cDescription*/,; //Descrição da Funcionalidade
					"MGLT031"  							/*cPerg*/		,; //Configuração dos Parâmetros
					{}									/*aInfoCustom*/	,; //Opções adicionais para o painel lateral
					.F.									/*lPanelAux*/	,; //Define criação do Painel auxiliar
					0									/*nSizePanelAux*/,; //Tamanho do Painel Auxiliar
					''									/*cDescriAux*/	,; //Descrição do Painel Auxiliar
					.F.									/*lViewExecute*/,; //Se .T. exibe o painel de execução. Se falso, apenas executa a função sem exibir a régua de processamento.
                    .F.                                 /*lOneMeter*/	,; //Se .T. cria apenas uma regua de processamento.
					.T.									/*lSchedAuto*/	)  //Se .T. habilita o botão de processamento em segundo plano (execução ocorre pelo Scheduler)

Return

/*
===============================================================================================================================
Programa----------: MGLT031P
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 24/03/2025
Descrição---------: Realiza o processamento da rotina.
Parametros--------: _oSelf
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGLT031P(_oSelf as Object)

Local _aHeadStr     := {}  As Array
Local cPostParms    := "" As Character
Local _cToken       := "" As Character
Local _cEmpCFG      := SuperGetMv('IT_ITAAPPQ',.F.,"000005") As Character
Local _jJSon        := Nil As JSon
Local _oRest        := Nil As Object
Local _cResult      := "" As Character
Local _nI, _nX      := 0 As Numeric
Local _aProd        := {} As Array
Local _aTipPrd      := {} As Array
Local _cAlias       := "" As Character
Local _aErro        := {} As Array
Local _cFornec      := "" As Character
Local _cLjForn      := "" As Character
Local _cCNPJFor     := "" As Character
Local _cTransp      := "" As Character
Local _cLjTran      := "" As Character
Local _cCNPJTran    := "" As Character
Local _cItem        := "" As Character
Local _cMsgAux      := "" As Character
Local _cDadosJson   := "" As Character
Local _cFormLogId   := "" As Character
Local _nCodProd     := 0 As Numeric
Local _lGrava       := .F. As Logical
Local _cUpdate      := "" As Character

DBSelectArea("ZFM")
ZFM->(DBSetOrder(1))
If ZFM->(DBSeek(xFilial("ZFM")+_cEmpCFG)) .And. !(Empty(ZFM->ZFM_LINK01) .Or. Empty(ZFM->ZFM_LINK02))

    _oRest := FwRest():New(ZFM->ZFM_LINK01)
    aAdd(_aHeadStr,"Content-Type: application/json") 
    cPostParms := '{"username": "'+ AllTrim(ZFM->ZFM_USRNOM) + '",'
    cPostParms += '"password": "'+  AllTrim(ZFM->ZFM_SENHA) +'"}'
    _oRest:SetPath("")
    _oRest:SetPostParams(cPostParms)

    If _oRest:Post(_aHeadStr)
        _jJson := JsonObject():new()
        
        If ValType(_cResult := _jJSon:FromJSON(_oRest:GetResult())) == "U" //Nil indica que conseguiu popular o objeto com o Json
            If _jJSon[1]:HasProperty("message")
                _cToken := _jJSon[1]["message"]
            Else
                FWAlertWarning("Não foi possivel recuperar o token de acesso. "+ _oRest:getLastError(),"MGLT03101")
            EndIf
        Else
            FWAlertWarning("Não foi possível ler o JSon retornado o Token de acesso ao Webservice do App da Qualidade." + _oRest:getLastError(),"MGLT03102")
        EndIf
        FreeObj(_oRest)
        FreeObj(_jJSon)
    EndIf
    If !Empty(_cToken)
        //Cod integração/Cod Protheus/Descrição/Processado/processado anteriormente/erro
        aAdd(_aTipPrd,{"1","Creme de Leite",0,0,0})
        aAdd(_aTipPrd,{"2","Soro de Leite",0,0,0})
        aAdd(_aTipPrd,{"3","Leite Cru",0,0,0})

        _cAlias := GetNextAlias()
        BeginSql alias _cAlias
            SELECT DISTINCT ZA7_TIPPRD, ZA7_DENMIN, ZA7_DENMAX, ZA7_DENPAD,ZA7_GORMIN, ZA7_GORMAX, ZA7_ESTMIN, ZA7_ESTMAX, ZA7_DPADIN,
            TRIM(REGEXP_SUBSTR(ZA7_CODINT, '[^;]+', 1, LEVEL)) AS ZA7_CODINT
            FROM %Table:ZA7% ZA7
            WHERE ZA7.D_E_L_E_T_ = ' '
            AND ZA7_FILIAL = %xFilial:ZA7%
            AND ZA7_CODINT <> ' '
            CONNECT BY LEVEL <= REGEXP_COUNT(ZA7_CODINT, ';') + 1
            AND PRIOR ZA7_TIPPRD = ZA7_TIPPRD
            AND PRIOR SYS_GUID() <> ' '
        EndSql
        While (_cAlias)->(!Eof())
            aAdd(_aProd,{(_cAlias)->ZA7_TIPPRD,; //01
                        (_cAlias)->ZA7_CODINT,; //02
                        (_cAlias)->ZA7_DPADIN,; //03
                        (_cAlias)->ZA7_DENMIN,; //04
                        (_cAlias)->ZA7_DENMAX,; //05
                        (_cAlias)->ZA7_DENPAD,; //06
                        (_cAlias)->ZA7_GORMIN,; //07
                        (_cAlias)->ZA7_GORMAX,; //08
                        (_cAlias)->ZA7_ESTMIN,; //09
                        (_cAlias)->ZA7_ESTMAX}) //10
                        
            (_cAlias)->(DBSkip())
        EndDo
        (_cAlias)->(DBCloseArea())
        ZZX->(DBSetOrder(4)) // ZZX_FILIAL+ZZX_FLOGID
        ZAP->(DBSetOrder(2)) // ZAP_FILIAL+ZAP_FLOGID+ZAP_ITEM
        ZBQ->(DBSetOrder(1)) //ZBQ_FILIAL+ZBQ_FLOGID+ZBQ_GRUPO
        ZZV->(DBSetOrder(1)) //ZZV_FILIAL+ZZV_PLACA

	    _oSelf:SetRegua1(Len(_aTipPrd))
        For _nI := 1 To Len(_aTipPrd)
        	_aHeadStr := {}
            _oSelf:IncRegua1("Processando produto " + _aTipPrd[_nI,2])
            _oRest := FwRest():New(ZFM->ZFM_LINK02)
            aAdd(_aHeadStr,"Content-Type: application/json") 
            aAdd(_aHeadStr,"Authorization: Bearer " + AllTrim(_cToken)) 

            _jJSon := JsonObject():New()
            // A data e hora para a recuperação dos dados no formato ISO 8601 (yyyy-MM-ddTHH:mm:ss). No banco da aplicação a informação é gravada em UTC 0. 
            // A aplicação vai converter o horário que For enviado no UTC-0
            // Necessário excluir o indicador Zulo (Z). o Filtro é realizado no campo DataEntrada
            _jJSon["StartDate"]         := FWTimeStamp(3,MV_PAR01,"00:00:00")
            _jJSon["EndDate"]           := FWTimeStamp(3,MV_PAR02,"23:59:59")
            _jJSon["ProductId"]         := _aTipPrd[_nI,1]
            _jJSon["SourceLocationId"]  := "All"
            
            cPostParms := _jJSon:toJson()
            _oRest:SetPath("")
            _oRest:SetPostParams(cPostParms)
            
            If _oRest:Post(_aHeadStr)
                _jJson := JsonObject():new()
                _cResult := DecodeUTF8(_oRest:GetResult(),"CP1252")//Decodifico para mantar a acentuação
                //As propriedades dos produtos são enviadas com número antes, ex: 01 pH ou 02 pH, dependendo do produto.
                //Retiro esse sequencial para que as propriedades tenham sempre os mesmos nomes
                For _nX := 1 To 10//limitei a 10 eventos
                    _cResult := StrTran(_cResult,'"'+StrZero(_nX,2,0)+' ','"')
                    //Ajusto também a Densidade que tem duas nomenclaruras
                    _cResult := StrTran(_cResult,' a 15ºC','')
                Next _nx
                If ValType(_jJSon:FromJSON(_cResult)) == "U" //Nil indica que conseguiu popular o objeto com o Json
                    //Sempre é retornado um Json com 1 item e dentro desse item, todas as análises
                    _oSelf:SetRegua2(Len(_jJSon))
                    For _nX := 1 To Len(_jJSon)
                        _lGrava := .F.
                        _oSelf:IncRegua2("Processando... Aguarde...")
                        
                        //Valido se o JSon possui alguma estrutura
                        If !_jJSon[_nX]:HasProperty("FormLogId")
                            aAdd(_aErro,{"FormLogId inválido. Posição do Json: " + StrZero(_nX,6)})
                            _aTipPrd[_nI,5]++
                            Loop
                        Else
                            _cFormLogId := StrZero(_jJSon[_nX]["FormLogId"],10)
                        EndIf

                        //Verifico se o produto recebido está devidamente configurado
                        If (_nCodProd:= aScan(_aProd,{|x| Upper(FwNoAccent(AllTrim(_jJSon[_nX]["Produto"]))) == AllTrim(x[2])})) == 0
                            aAdd(_aErro,{"Produto não configurado para integração: "+_jJSon[_nX]["Produto"]+". FormLogId:"+_cFormLogId})
                            _aTipPrd[_nI,5]++
                            Loop
                        EndIf

                        _cCNPJFor := StrTran(StrTran(StrTran(_jJSon[_nX]["Cliente_CPF_CNPJ"],".",""),"-",""),"/","")
                        _cCNPJTran := StrTran(StrTran(StrTran(_jJSon[_nX]["Transportadora_CPF_CNPJ"],".",""),"-",""),"/","")
                        _cPlaca := StrTran(_jJSon[_nX]["Placa"],"-","")
                        _cDadosJson := _jJSon[_nX]:toJson()   // Retorna um JSon TXT 

                        //Produtor
                        _cAlias:=GetNextAlias()
                        BeginSql alias _cAlias
                        SELECT A2_COD, A2_LOJA FROM %Table:SA2% WHERE A2_CGC = %exp:_cCNPJFor%
                            AND D_E_L_E_T_ = ' ' AND A2_MSBLQL = '2' 
                            AND A2_I_CLASS IN ('F','L','Z') AND A2_L_KMLE > 0
                            ORDER BY A2_COD
                        EndSql
                        _cFornec := (_cAlias)->A2_COD
                        _cLjForn := (_cAlias)->A2_LOJA
                        (_cAlias)->(DBCloseArea())
                        If Empty(_cFornec)
                            aAdd(_aErro,{"Fornecedor não localizado: "+_jJSon[_nX]["Cliente_CPF_CNPJ"]+". FormLogId:"+_cFormLogId})
                            _aTipPrd[_nI,5]++
                        Else
                            //Transportador
                            _cAlias:=GetNextAlias()
                            BeginSql alias _cAlias
                                SELECT A2_COD, A2_LOJA FROM %Table:SA2% SA2, %Table:ZZV% ZZV
                                WHERE A2_CGC = %exp:_cCNPJTran%
                                AND ZZV_FILIAL = %xFilial:ZZV%
                                AND ZZV_PLACA = %exp:_cPlaca%
                                AND ZZV_TRANSP = A2_COD
                                AND ZZV_LJTRAN = A2_LOJA
                                AND SA2.D_E_L_E_T_ = ' ' 
                                AND ZZV.D_E_L_E_T_ = ' '
                                AND A2_MSBLQL = '2'
                                AND ZZV_MSBLQL = '2'
                                ORDER BY A2_COD
                            EndSql
                            _cTransp := (_cAlias)->A2_COD
                            _cLjTran := (_cAlias)->A2_LOJA
                            (_cAlias)->(DBCloseArea())
                            If Empty(_cTransp)
                                aAdd(_aErro,{"Relacionamento Placa/Transportador não localizado: "+_jJSon[_nX]["Placa"]+" / ";
                                    +_jJSon[_nX]["Transportadora_CPF_CNPJ"]+". FormLogId:"+_cFormLogId})
                                _aTipPrd[_nI,5]++
                            EndIf
                        EndIf
                                                
                        BEGIN TRANSACTION
                        If Empty(_cTransp) .Or. Empty(_cFornec)
                            If ZZX->(MsSeek(xFilial("ZZX")+_cFormLogId))
                                If ZZX->ZZX_ANAUSE == .F.
                                    ZZX->(RecLock("ZZX", .F.))
                                    ZZX->(DBDelete())
                                    ZZX->(MSUnLock())
                                    _cUpdate 	:= "UPDATE "+RetSQLName("ZAP") + " SET D_E_L_E_T_ = '*', R_E_C_D_E_L_ = R_E_C_N_O_ "
                                    _cUpdate	+= "WHERE D_E_L_E_T_ = ' ' "
                                    _cUpdate	+= "AND ZAP_FILIAL = '"+cFilAnt+"' "
                                    _cUpdate	+= "AND ZAP_FLOGID = '"+_cFormLogId+"' "
                                    If TCSqlExec( _cUpdate ) < 0
                                        FWAlertError("Erro na exclusão dos movimentos. Favor acionar a TI. Erro: "+AllTrim(TCSQLError()),"MGLT03103")
                                    Else
                                        aAdd(_aErro,{"Transportador/Fornecedor modificado mas não localizado. Análise excluída (ZZX/ZAP). FormLogId:"+_cFormLogId})
                                    EndIf
                                           
                                    _cUpdate 	:= "UPDATE "+RetSQLName("ZBQ") + " SET D_E_L_E_T_ = '*', R_E_C_D_E_L_ = R_E_C_N_O_ "
                                    _cUpdate	+= "WHERE D_E_L_E_T_ = ' ' "
                                    _cUpdate	+= "AND ZBQ_FLOGID = '"+_cFormLogId+"' "
                                    If TCSqlExec( _cUpdate ) < 0
                                        FWAlertError("Erro na exclusão dos movimentos. Favor acionar a TI. Erro: "+AllTrim(TCSQLError()),"MGLT03103")
                                    Else
                                        aAdd(_aErro,{"Transportador/Fornecedor modificado mas não localizado. Integração (ZQB) excluída. FormLogId:"+_cFormLogId})
                                    EndIf
                                Else
                                    aAdd(_aErro,{"Transportador/Fornecedor modificado mas não localizado. Análise já vinculada. Não foi possível realizar sua exclusão FormLogId:"+_cFormLogId})
                                EndIf
                            EndIf
                        // Gravar Tabela de Muro
                        ElseIf !ZBQ->(DBSeek(xFilial("ZBQ")+_cFormLogId+_jJSon[_nX]["Grupo"]))
                            _lGrava := .T.
                            ZBQ->(RecLock("ZBQ",.T.))
                            ZBQ->ZBQ_FILIAL := cFilant //C 2 0 
                            ZBQ->ZBQ_FLOGID := _cFormLogId //C 10 0
                            ZBQ->ZBQ_GRUPO := _jJSon[_nX]["Grupo"] //C 15 0
                            ZBQ->ZBQ_TIPPRD := _jJSon[_nX]["TipoProduto"] //C 20 0
                            ZBQ->ZBQ_PRODUT := FwNoAccent(_jJSon[_nX]["Produto"]) //C 60 0
                        //Atualiza as informações quando a Qualidade realizar a liberação.
                        ElseIf !ValType(_jJSon[_nX]["DataLiberação"])=="J" .And. !Empty(_jJSon[_nX]["DataLiberação"]) .And. Empty(ZBQ->ZBQ_DTLIBE)
                            _lGrava := .T.
                            ZBQ->(RecLock("ZBQ",.F.))
                        EndIf
                        If _lGrava
                            ZBQ->ZBQ_DTINTE := Date() //D 8 0
                            ZBQ->ZBQ_HRINTE := Time() //C 8 0
                            ZBQ->ZBQ_MAXDAT := DToC(FwDateTimeToLocal(_jJSon[_nX]["max(Data)"])[1])+" "+FwDateTimeToLocal(_jJSon[_nX]["max(Data)"])[2] //C 20 0
                            ZBQ->ZBQ_AMOSTR := _jJSon[_nX]["Amostra"] //N 2 0
                            ZBQ->ZBQ_CNPJTR := _cCNPJTran //C 14 0
                            ZBQ->ZBQ_PLACA := _cPlaca //C 8 0
                            ZBQ->ZBQ_CNPJOR := _cCNPJFor //C 14 0
                            ZBQ->ZBQ_ORIGEM := _jJSon[_nX]["Origem"] //C 80 0
                            //As datas são recebidas em UTC-0 mas devemos gravar no nosso fuso (-3:00), por isso a conversão
                            ZBQ->ZBQ_DTENTR := DToC(FwDateTimeToLocal(Replace(_jJSon[_nX]["DataEntrada"]," ","T"))[1])+" "+FwDateTimeToLocal(Replace(_jJSon[_nX]["DataEntrada"]," ","T"))[2] //C 20 0
                            ZBQ->ZBQ_DTCOLE := DToC(FwDateTimeToLocal(Replace(_jJSon[_nX]["DataColeta"]," ","T"))[1])+" "+FwDateTimeToLocal(Replace(_jJSon[_nX]["DataColeta"]," ","T"))[2] //C 20 0
                            ZBQ->ZBQ_DTCHEG := DToC(FwDateTimeToLocal(Replace(_jJSon[_nX]["DataChegada"]," ","T"))[1])+" "+FwDateTimeToLocal(Replace(_jJSon[_nX]["DataChegada"]," ","T"))[2] //C 20 0
                            ZBQ->ZBQ_DTLIBE := If(ValType(_jJSon[_nX]["DataLiberação"])=="J","",DToC(FwDateTimeToLocal(Replace(_jJSon[_nX]["DataLiberação"]," ","T"))[1])+" "+FwDateTimeToLocal(Replace(_jJSon[_nX]["DataLiberação"]," ","T"))[2]) //C 20 0
                            ZBQ->ZBQ_DTINIC := If(ValType(_jJSon[_nX]["DataInicio"])=="J","",DToC(FwDateTimeToLocal(Replace(_jJSon[_nX]["DataInicio"]," ","T"))[1])+" "+FwDateTimeToLocal(Replace(_jJSon[_nX]["DataInicio"]," ","T"))[2]) //C 20 0
                            ZBQ->ZBQ_DTFIM := If(ValType(_jJSon[_nX]["DataFim"])=="J","",DToC(FwDateTimeToLocal(Replace(_jJSon[_nX]["DataFim"]," ","T"))[1])+" "+FwDateTimeToLocal(Replace(_jJSon[_nX]["DataFim"]," ","T"))[2]) //C 20 0
                            ZBQ->ZBQ_VOLUME := Val(_jJSon[_nX]["Volume"]) //N 16 4
                            ZBQ->ZBQ_TEMPER := If(_jJSon[_nX]:HasProperty("Temperatura"),If(ValType(_jJSon[_nX]["Temperatura"])=="J",0,Val(_jJSon[_nX]["Temperatura"])),0) //N 6 2
                            ZBQ->ZBQ_SENSOR := If(_jJSon[_nX]:HasProperty("Sensorial"),If(ValType(_jJSon[_nX]["Sensorial"])=="J","",_jJSon[_nX]["Sensorial"]),"") //C 12 0
                            ZBQ->ZBQ_ESTALC := If(_jJSon[_nX]:HasProperty("Estabilidade Alcoólica"),If(ValType(_jJSon[_nX]["Estabilidade Alcoólica"])=="J","",_jJSon[_nX]["Estabilidade Alcoólica"]),"") //C 15 0
                            ZBQ->ZBQ_GRAALC := If(_jJSon[_nX]:HasProperty("Graduação Alcoólica"),If(ValType(_jJSon[_nX]["Graduação Alcoólica"])=="J",0,Val(_jJSon[_nX]["Graduação Alcoólica"])),0) //N 8 3
                            ZBQ->ZBQ_ACIDEZ := If(_jJSon[_nX]:HasProperty("Acidez"),If(ValType(_jJSon[_nX]["Acidez"])=="J",0,Val(_jJSon[_nX]["Acidez"])),0) //N 8 3
                            ZBQ->ZBQ_DENSID := If(_jJSon[_nX]:HasProperty("Densidade"),If(ValType(_jJSon[_nX]["Densidade"])=="J",0,Val(_jJSon[_nX]["Densidade"])),0) //N 10 3
                            ZBQ->ZBQ_GORDUR := If(_jJSon[_nX]:HasProperty("Gordura"),If(ValType(_jJSon[_nX]["Gordura"])=="J",0,Val(_jJSon[_nX]["Gordura"])),0) //N 8 3
                            ZBQ->ZBQ_OBSFQ1 := If(_jJSon[_nX]:HasProperty("Observação Fisico Quimico 1"),If(ValType(_jJSon[_nX]["Observação Fisico Quimico 1"])=="J","",_jJSon[_nX]["Observação Fisico Quimico 1"]),"") //C 100 0
                            ZBQ->ZBQ_EST := If(_jJSon[_nX]:HasProperty("EST"),If(ValType(_jJSon[_nX]["EST"])=="J",0,Val(_jJSon[_nX]["EST"])),0) //N 9 3
                            ZBQ->ZBQ_ESD := If(_jJSon[_nX]:HasProperty("ESD"),If(ValType(_jJSon[_nX]["ESD"])=="J",0,Val(_jJSon[_nX]["ESD"])),0) //N 9 3
                            ZBQ->ZBQ_CRIOSC := If(_jJSon[_nX]:HasProperty("Crioscopia"),If(ValType(_jJSon[_nX]["Crioscopia"])=="J",0,Val(_jJSon[_nX]["Crioscopia"])),0) //N 9 4
                            ZBQ->ZBQ_PROTEI := If(_jJSon[_nX]:HasProperty("Proteina"),If(ValType(_jJSon[_nX]["Proteina"])=="J",0,Val(_jJSon[_nX]["Proteina"])),0) //N 8 3
                            ZBQ->ZBQ_PH := If(_jJSon[_nX]:HasProperty("pH"),If(ValType(_jJSon[_nX]["pH"])=="J",0,Val(_jJSon[_nX]["pH"])),0) //N 8 3
                            ZBQ->ZBQ_ANTIBI := If(_jJSon[_nX]:HasProperty("Antibiotico - PPRO 1"),If(ValType(_jJSon[_nX]["Antibiotico - PPRO 1"])=="J",0,Val(_jJSon[_nX]["Antibiotico - PPRO 1"])),0) //N 9 4
                            ZBQ->ZBQ_OBSFQ2 := If(_jJSon[_nX]:HasProperty("Observação Fisico Quimico 2"),If(ValType(_jJSon[_nX]["Observação Fisico Quimico 2"])=="J","",_jJSon[_nX]["Observação Fisico Quimico 2"]),"") //C 100 0 
                            ZBQ->ZBQ_PEROHI := If(_jJSon[_nX]:HasProperty("01 Peroxido de Hidrogenio"),If(ValType(_jJSon[_nX]["01 Peroxido de Hidrogenio"])=="J","",_jJSon[_nX]["01 Peroxido de Hidrogenio"]),"") //C 15 0
                            ZBQ->ZBQ_FORMAL := If(_jJSon[_nX]:HasProperty("Formaldeido"),If(ValType(_jJSon[_nX]["Formaldeido"])=="J","",_jJSon[_nX]["Formaldeido"]),"") //C 15 0
                            ZBQ->ZBQ_OBSCON := If(_jJSon[_nX]:HasProperty("Observação Conservantes"),If(ValType(_jJSon[_nX]["Observação Conservantes"])=="J","",_jJSon[_nX]["Observação Conservantes"]),"") //C 100 0
                            ZBQ->ZBQ_ACIROS := If(_jJSon[_nX]:HasProperty("01 Acido Rosolico"),If(ValType(_jJSon[_nX]["01 Acido Rosolico"])=="J","",_jJSon[_nX]["01 Acido Rosolico"]),"") //C 15 0
                            ZBQ->ZBQ_FENOLF := If(_jJSon[_nX]:HasProperty("Fenolftaleína"),If(ValType(_jJSon[_nX]["Fenolftaleína"])=="J","",_jJSon[_nX]["Fenolftaleína"]),"") //C 15 0
                            ZBQ->ZBQ_OBSNEU := If(_jJSon[_nX]:HasProperty("Observação Neutralizantes"),If(ValType(_jJSon[_nX]["Observação Neutralizantes"])=="J","",_jJSon[_nX]["Observação Neutralizantes"]),"") //C 100 0
                            ZBQ->ZBQ_CLORET := If(_jJSon[_nX]:HasProperty("Cloreto"),If(ValType(_jJSon[_nX]["Cloreto"])=="J","",_jJSon[_nX]["Cloreto"]),"") //C 15 0
                            ZBQ->ZBQ_ALCETI := If(_jJSon[_nX]:HasProperty("Alcool Etilico"),If(ValType(_jJSon[_nX]["Alcool Etilico"])=="J","",_jJSon[_nX]["Alcool Etilico"]),"") //C 15 0
                            ZBQ->ZBQ_AMIDO := If(_jJSon[_nX]:HasProperty("Amido"),If(ValType(_jJSon[_nX]["Amido"])=="J","",_jJSon[_nX]["Amido"]),"") //C 15 0
                            ZBQ->ZBQ_SACARO := If(_jJSon[_nX]:HasProperty("Sacarose"),If(ValType(_jJSon[_nX]["Sacarose"])=="J","",_jJSon[_nX]["Sacarose"]),"") //C 15 0
                            ZBQ->ZBQ_OBSREC := If(_jJSon[_nX]:HasProperty("Observação Reconstituintes"),If(ValType(_jJSon[_nX]["Observação Reconstituintes"])=="J","",_jJSon[_nX]["Observação Reconstituintes"]),"") //C 100 0
                            ZBQ->ZBQ_FOSALC := If(_jJSon[_nX]:HasProperty("Fosfatase Alcalina"),If(ValType(_jJSon[_nX]["Fosfatase Alcalina"])=="J","",_jJSon[_nX]["Fosfatase Alcalina"]),"") //M 10 0
                            ZBQ->ZBQ_PEROXI := If(_jJSon[_nX]:HasProperty("Peroxidase"),If(ValType(_jJSon[_nX]["Peroxidase"])=="J","",_jJSon[_nX]["Peroxidase"]),"") //M 10 0
                            ZBQ->ZBQ_OBSTRA := If(_jJSon[_nX]:HasProperty("Observação Tratamento Térmico"),If(ValType(_jJSon[_nX]["Observação Tratamento Térmico"])=="J","",_jJSon[_nX]["Observação Tratamento Térmico"]),"") //M 10 0
                            ZBQ->ZBQ_DESTIN := If(_jJSon[_nX]:HasProperty("Destino"),If(ValType(_jJSon[_nX]["Destino"])=="J","",_jJSon[_nX]["Destino"]),"") //C 12 0
                            ZBQ->ZBQ_JSON := _cDadosJson //M 10 0
                            ZBQ->ZBQ_SIF := If(_jJSon[_nX]:HasProperty("SIF"),Val(_jJSon[_nX]["SIF"]),0) //N 14 3
                            ZBQ->(MSUnLock())
                        
                            //Somente realizar a integração quando a Qualidade liberar a análise
                            If Empty(ZBQ->ZBQ_DTLIBE)
                                aAdd(_aErro,{"Anáise não finalizada pela qualidade. FormLogId: "+_cFormLogId})
                                _aTipPrd[_nI,5]++
                            ElseIf ZBQ->ZBQ_DENSID == 0
                                aAdd(_aErro,{"Densidade não informada. FormLogId: "+_cFormLogId})
                                _aTipPrd[_nI,5]++
                            //Densidade difernte de 1 precisa estar dentro da faixa de tolerância
                            ElseIf _aProd[_nCodProd,3] <> "1" .And. (ZBQ->ZBQ_DENSID < _aProd[_nCodProd,4] .Or. ZBQ->ZBQ_DENSID > _aProd[_nCodProd,5])
                                aAdd(_aErro,{"Densidade "+Str(ZBQ->ZBQ_DENSID)+" fora da taxa de tolerância: "+Str(_aProd[_nCodProd,4]) +" a "+ Str(_aProd[_nCodProd,5]) +". FormLogId: "+_cFormLogId})
                                _aTipPrd[_nI,5]++
                            //Gordura
                            ElseIf ZBQ->ZBQ_GORDUR < _aProd[_nCodProd,7] .Or. ZBQ->ZBQ_GORDUR > _aProd[_nCodProd,8]
                                aAdd(_aErro,{"Gordura "+Str(ZBQ->ZBQ_GORDUR)+" fora da taxa de tolerância: "+Str(_aProd[_nCodProd,7]) +" a "+ Str(_aProd[_nCodProd,8]) +". FormLogId: "+_cFormLogId})
                                _aTipPrd[_nI,5]++
                            //EST
                            ElseIf ZBQ->ZBQ_EST < _aProd[_nCodProd,9] .Or. ZBQ->ZBQ_EST > _aProd[_nCodProd,10]
                                aAdd(_aErro,{"EST "+Str(ZBQ->ZBQ_EST)+" fora da taxa de tolerância: "+Str(_aProd[_nCodProd,9]) +" a "+ Str(_aProd[_nCodProd,10]) +". FormLogId: "+_cFormLogId})
                                _aTipPrd[_nI,5]++
                            Else
                                If ! ZZX->(MsSeek(xFilial("ZZX")+_cFormLogId))
                                    // Grava os dados de capa - ZZX - Capa
                                    ZZX->(RecLock("ZZX",.T.))
                                    ZZX->ZZX_FILIAL := cFilAnt
                                    ZZX->ZZX_CODIGO := GETSXENUM("ZZX","ZZX_CODIGO")
                                    ZZX->ZZX_CODPRD := _aProd[_nCodProd,1]
                                    ZZX->ZZX_DATA   := CToD(ZBQ->ZBQ_DTENTR)
                                    ZZX->ZZX_HORA   := SubStr(ZBQ->ZBQ_DTENTR,12,5)
                                    ZZX->ZZX_FORNEC := _cFornec // Código do Produtor
                                    ZZX->ZZX_LJFORN := _cLjForn // Loja do Produtor
                                    ZZX->ZZX_PLACA  := _cPlaca    //_jJSon[_nX]["Placa"]
                                    ZZX->ZZX_TRANSP := _cTransp // Código da Transportadora
                                    ZZX->ZZX_LJTRAN := _cLjTran // Loja da Transportadora
                                    ZZX->ZZX_DENSID := If(_aProd[_nCodProd,3] == "1",_aProd[_nCodProd,6],ZBQ->ZBQ_DENSID) //1-Indica usar o valor padrão
                                    ZZX->ZZX_ANAUSE := .F.
                                    ZZX->ZZX_FLOGID := _cFormLogId
                                    ZZX->(MSUnLock())
                                    If __lSX8
                                        ConfirmSX8()
                                    Else
                                        RollBackSx8()
                                    EndIf
                                EndIf
                                
                                _cItem := _jJSon[_nX]["Grupo"] + Space(5)
                                _cItem := StrZero(Val(AllTrim(SubStr(_cItem,At( "_",_cItem)+1,2))),2)

                                If !ZAP->(MsSeek(ZZX->(ZZX_FILIAL+ZZX_FLOGID)+_cItem)) // Já foi feita a inclusão deste item.
                                    // Grava os dados de item - ZAP - Item
                                    ZAP->(RecLock("ZAP",.T.))
                                    ZAP->ZAP_FILIAL := ZZX->ZZX_FILIAL
                                    ZAP->ZAP_CODIGO := ZZX->ZZX_CODIGO
                                    ZAP->ZAP_ITEM   := _cItem //_jJSon[_nX]["Grupo"]
                                    ZAP->ZAP_GORD   := ZBQ->ZBQ_GORDUR
                                    ZAP->ZAP_EST    := ZBQ->ZBQ_EST
                                    ZAP->ZAP_FLOGID := ZZX->ZZX_FLOGID
                                    ZAP->(MSUnLock()) 
                                    _aTipPrd[_nI,3]++
                                Else
                                    _aTipPrd[_nI,4]++
                                EndIf
                            EndIf
                        EndIf
                        END TRANSACTION
                    Next _nX
                Else
                    FWAlertWarning("Não foi possível ler o JSon com as informações do App da Qualidade." + _oRest:getLastError(),"MGLT03104")
                EndIf
            EndIf
            FreeObj(_oRest)
            FreeObj(_jJSon)
            _cMsgAux += "["+_aTipPrd[_nI,2]+Space(20-Len(_aTipPrd[_nI,2]))+"] Incluídos: "+AllTrim(Str(_aTipPrd[_nI,3],10)) + " Já processados: "+AllTrim(Str(_aTipPrd[_nI,4],10));
                    +" Com erro: "+AllTrim(Str(_aTipPrd[_nI,5],10))+ CRLF
        Next _nI
        FWAlertWarning("Termino da integração Webservice Protheus x App da Qualidade. "+CRLF+ _cMsgAux,"MGLT03105")
        If Len(_aErro) > 0 .And. !FWGetRunSchedule()
            U_ITListBox( 'Log de Processamento' , {"Erros"} , _aErro , .F. , 1 , 'Verifique os registros apresentados' )
        EndIf
        FreeObj(_oRest)
        FreeObj(_jJSon)
    EndIf
Else
    FWAlertWarning("Não foi encontrada regras de configuração para essa integração na tabela ZFM","MGLT03106")
EndIf

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} Scheddef
    Função para definição de parametros na tela de schedule
@author Lucas Borges Ferreira
@since 19/03/2025
//-----------------------------------------------------------------*/
Static Function Scheddef()
    Local aParam := {} as array
    Local aOrd := {} as array

    aAdd(aParam, "P"        ) // 01 - Tipo R para relatorio P para processo
    aAdd(aParam, "MGLT031") // 02 - Pergunte do relatorio, caso nao use passar ParamDef
    aAdd(aParam, ""         ) // 03 - Alias
    aAdd(aParam, aOrd       ) // 04 - Array de ordens
    aAdd(aParam, ""         ) // 05 - Titulo
    aAdd(aParam, ""         ) // 06 - Nome do relatório (parametro 1 do metodo new da classe TReport)
 
Return aParam
