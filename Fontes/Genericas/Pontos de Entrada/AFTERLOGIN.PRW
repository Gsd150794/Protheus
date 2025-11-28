/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |02/10/2025| Chamado 51526. Modificada forma para recuperar a matrícula do usuário.
Lucas Borges  |07/10/2025| Chamado 52175. Incluído parâmetro MV_FNPCTSS
Lucas Borges  |31/10/2025| Chamado 52806. Corrigidas as portas do ambiente Fiscal
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: AFTERLOGIN
Autor-----------: Josué Danich Prestes
Data da Criacao-: 24/05/2019
Descrição-------: Ponto de entrada chamado na inicialização do Protheus - Chamado 29050
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AfterLogin

Local _aArea    := FWGetArea() As Array
Local _aStruZZL := ZZL->(Dbstruct()) As Array
Local _nI       := 0 As Numeric
Local _cAmbiente:= " " As Character
Local _xCont    := " " As Variant
Local _nPortTAF := 0 As Numeric
Local _aEnv     := {} As Array
Local _nX       := 0 As Numeric
        
//Valida se usuário existe na ZZL e cria se não existir
ZZL->(DBSetOrder(3))
If !(ZZL->(DBSeek(xFilial("ZZL")+__cUserId)))
    ZZL->(RecLock("ZZL",.T.))
    ZZL->ZZL_CODUSU := __cUserId
    ZZL->ZZL_USER   := cUserName
    ZZL->ZZL_NOME   := FWSFAllUsers({__cUserID},{"USR_NOME"})[1][3]
    ZZL->ZZL_EMAIL  := FWSFAllUsers({__cUserID},{"USR_EMAIL"})[1][3]
    ZZL->ZZL_MATRIC := FWSFAllUsers({__cUserID},{"USR_FILIAL"})[1][3]+FWSFAllUsers({__cUserID},{"USR_CODFUNC"})[1][3]
    For _nI := 1 To Len(_aStruZZL)
        If 	AllTrim(_aStruZZL[_nI][1]) <> "ZZL_FILIAL" .And. AllTrim(_aStruZZL[_nI][1]) <> "ZZL_CODUSU" .And. ;
            AllTrim(_aStruZZL[_nI][1]) <> "ZZL_USER" .And. AllTrim(_aStruZZL[_nI][1]) <> "ZZL_MATRIC" .And. ;
            AllTrim(_aStruZZL[_nI][1]) <> "ZZL_NOME" .And. AllTrim(_aStruZZL[_nI][1]) <> "ZZL_EMAIL" 
            If !Empty(GetSX3Cache(_aStruZZL[_nI][1],"X3_RELACAO"))
                (ZZL->&(GetSX3Cache(_aStruZZL[_nI][1],"X3_CAMPO"))) := &(GetSX3Cache(_aStruZZL[_nI][1],"X3_RELACAO"))
            EndIf
        EndIf
    Next _nI
    ZZL->(MSUnLock())
EndIf

FWMakeDir(__RelDir)

//====================================
//Ajustes para os ambientes de teste
//====================================
_cAmbiente := U_AmbTeste("Alias")
_nPortTAF := Val(U_AmbTeste("Port"))
 
If !Empty(_cAmbiente) .Or. _cAmbiente == _cStrError
    If _cAmbiente <> "PRODUCAO"
        aAdd(_aEnv,{"SIMULACAO","MV_SPEDURL","https://protheusteste.italac.com.br:31707"})//Endereço do TSS
        aAdd(_aEnv,{"SIMULACAO","MV_TAFSURL","https://protheusteste.italac.com.br:31707"})//Endereço do TAF
        aAdd(_aEnv,{"SIMULACAO","IT_WSURL","https://protheusteste.italac.com.br:31706"})//Endereço do WS
        aAdd(_aEnv,{"SIMULACAO","IT_WFHOSTS","https://protheusteste.italac.com.br:31706/workflow/"})
        aAdd(_aEnv,{"SIMULACAO","IT_WEBLNK","https://protheusteste.italac.com.br:31706/ws/"})
        aAdd(_aEnv,{"SIMULACAO","MV_FNPCTSS",""})//Endereço do Rest do TSS para integração com Portal do Cliente

        aAdd(_aEnv,{"HOMOLOGACAO","MV_SPEDURL","https://protheusteste.italac.com.br:21707"})//Endereço do TSS
        aAdd(_aEnv,{"HOMOLOGACAO","MV_TAFSURL","https://protheusteste.italac.com.br:21707"})//Endereço do TAF
        aAdd(_aEnv,{"HOMOLOGACAO","IT_WSURL","https://protheusteste.italac.com.br:21706"})//Endereço do WS
        aAdd(_aEnv,{"HOMOLOGACAO","IT_WFHOSTS","https://protheusteste.italac.com.br:21706/workflow/"})
        aAdd(_aEnv,{"HOMOLOGACAO","IT_WEBLNK","https://protheusteste.italac.com.br:21706/ws/"})
        aAdd(_aEnv,{"HOMOLOGACAO","MV_FNPCTSS",""})//Endereço do Rest do TSS para integração com Portal do Cliente

        aAdd(_aEnv,{"DESENV","MV_SPEDURL","https://protheusteste.italac.com.br:11707"})//Endereço do TSS
        aAdd(_aEnv,{"DESENV","MV_TAFSURL","https://protheusteste.italac.com.br:11707"})//Endereço do TAF
        aAdd(_aEnv,{"DESENV","IT_WSURL","https://protheusteste.italac.com.br:11706"})//Endereço do WS
        aAdd(_aEnv,{"DESENV","IT_WFHOSTS","https://protheusteste.italac.com.br:11706/workflow/"})
        aAdd(_aEnv,{"DESENV","IT_WEBLNK","https://protheusteste.italac.com.br:11706/ws/"})
        aAdd(_aEnv,{"DESENV","MV_FNPCTSS","https://apirestdesenv.italac.com.br:11407/api/tss"})//Endereço do Rest do TSS para integração com Portal do Cliente

        aAdd(_aEnv,{"TMS","MV_SPEDURL","https://protheusteste.italac.com.br:41707"})//Endereço do TSS
        aAdd(_aEnv,{"TMS","MV_TAFSURL","https://protheusteste.italac.com.br:41707"})//Endereço do TAF
        aAdd(_aEnv,{"TMS","IT_WSURL","https://protheusteste.italac.com.br:41706"})//Endereço do WS
        aAdd(_aEnv,{"TMS","IT_WFHOSTS","https://protheusteste.italac.com.br:41706/workflow/"})
        aAdd(_aEnv,{"TMS","IT_WEBLNK","https://protheusteste.italac.com.br:41706/ws/"})
        aAdd(_aEnv,{"TMS","MV_FNPCTSS",""})//Endereço do Rest do TSS para integração com Portal do Cliente

        aAdd(_aEnv,{"FISCAL","MV_SPEDURL","https://protheusteste.italac.com.br:51707"})//Endereço do TSS
        aAdd(_aEnv,{"FISCAL","MV_TAFSURL","https://protheusteste.italac.com.br:51707"})//Endereço do TAF
        aAdd(_aEnv,{"FISCAL","IT_WSURL","https://protheusteste.italac.com.br:51706"})//Endereço do WS
        aAdd(_aEnv,{"FISCAL","IT_WFHOSTS","https://protheusteste.italac.com.br:51706/workflow/"})
        aAdd(_aEnv,{"FISCAL","IT_WEBLNK","https://protheusteste.italac.com.br:51706/ws/"})
        aAdd(_aEnv,{"FISCAL","MV_FNPCTSS",""})//Endereço do Rest do TSS para integração com Portal do Cliente
        aAdd(_aEnv,{"   ","MV_CHVNFE",.F.})//Consulta Chave na SEFAZ
        aAdd(_aEnv,{"   ","MV_INSIGHT",.F.})//Habilita Protheus Insight
        aAdd(_aEnv,{"   ","MV_TAFTALI",_cAmbiente})//DataBase do TAF
        aAdd(_aEnv,{"   ","MV_TAFPORT",_nPortTAF})//Porta do TAF
        aAdd(_aEnv,{"   ","IT_EMAILTR",.T.})//Indica se deve trocar os e-mails para dispararem para a conta sistema@italac.com.br
        aAdd(_aEnv,{"   ","MV_TSREP",.F.})//Define se haverá integração entre o modulo SIGAPON e o aplicativo Suricato

        //Configurações do TSS
        _cQuery := "UPDATE SPED000 SET CONTEUDO = '2' WHERE PARAMETRO IN ('MV_AMBIENT', 'MV_AMBCTEC', 'MV_AMBNFEC', 'MV_AMBCCE', 'MV_AMBMDFE','MV_MDAMB','MV_ACTEOS','MV_AMBEPP','MV_AMBCOT','MV_AMBCLE','MV_AMBNFCE','MV_NFSEAMB','MV_TCAMB3','MV_TCAMB2','MV_TCAMB1','MV_TCAMB0')"
        TCSqlExec( _cQuery )
        
        //Atualiza parâmetros
        For _nX := 1 To Len(_aEnv)
            If _cAmbiente == _aEnv[_nX][1] .Or. Empty(_aEnv[_nX][1])
                _xCont := SuperGetMV(_aEnv[_nX][2], .F.)
                If ValType(_xCont)=='S'
                    _xCont := AllTrim(_xCont)
                EndIf
                If _xCont <> _aEnv[_nX][3]
                    If _aEnv[_nX][2] == "IT_EMAILTR" .And. FWIsAdmin() .And. FWAlertYesNo("Ambiente de teste setado para enviar e-mails direto para o usuário ao "+;
                        "invés de direcionar para a conta sistema@italac.com.br. Deseja manter dessa forma?","AfterLogin02")
                        Loop
                    EndIf
                    PutMV(_aEnv[_nX][2],_aEnv[_nX][3])
                EndIf    
            EndIf
        Next _nX
    EndIf
Else
    FWAlertInfo("Ambiente não configurado para uso. Não utilize o ambiente e acione o departamento de Infra.","AfterLogin01")
EndIf

FWRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa--------: AmbTeste
Autor-----------: Lucas Borges Ferreira
Data da Criacao-: 11/07/2025
Descrição-------: Retorna se o ambiente corrente é um ambiente de testes. Normalmente utilizado para evitar que integrações e 
                  Workflows sejam executadao.
Parametros------: Nenhum
Retorno---------: _lRet -> C -> Retorna o conteúdo da chave solicitada
===============================================================================================================================
*/
User Function AmbTeste(_cChave As Character) As Character

Local _cIniFile := GetAdv97() As Character
Local _cStrError:= "ERROR" As Character
Local _cRet     := '' As Character

Default _cChave := "Alias" //"Port"

//Busca o nome da base na seção "DBAccess"
_cRet := GetPvProfString("DBAccess", _cChave, _cStrError, _cIniFile)

//Se não encontrou ou deu erro, ai vamos buscar novamente mas agora ao invés de "DBAccess" vamos usar a seção "TopConnect"
If Empty(_cRet) .Or. _cRet == _cStrError
    _cRet := GetPvProfString("TopConnect", _cChave, _cStrError, _cIniFile)
    //Se não encontrou ou deu erro, ai vamos buscar novamente mas agora ao invés de "TopConnect" vamos usar a seção "TotvsDBAccess"
    If Empty(_cRet) .Or. _cRet == _cStrError
        _cRet := GetPvProfString("TotvsDBAccess", _cChave, _cStrError, _cIniFile)
        //Se mesmo assim não encontrou, vamos buscar direto do ambiente
        If Empty(_cRet) .Or. _cRet == _cStrError
            _cRet := GetSrvProfString("DB"+_cChave, _cStrError)
        EndIf
    EndIf
EndIf

Return _cRet
