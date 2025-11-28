/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
       Autor      |    Data    |                                             Motivo                                           
-------------------------------------------------------------------------------------------------------------------------------
 Alex Wallauer    | 05/10/2017 | Ajustes para integraçõa do RDC com Pallet - Chamado 21743
 Josué Danich     | 06/03/2019 | Revisão para loboguara - Chamado 28356  
 Julio Paz        | 16/09/2020 | Correções nas formações dos nomes de campos da tabela temporária TRBPED. Chamado 34159.
==============================================================================================================================================================
Analista    - Programador   - Inicio   - Envio    - Chamado - Motivo da Alteração
==============================================================================================================================================================
Vanderlei   - Alex Wallauer - 25/02/24 -          - 49894   - Novo rateio de peso bruto por itens de NF, Campo novo DAI_I_FROL.
==============================================================================================================================================================
*/
//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOPCONN.ch"
#Include "TOTVS.ch"
#Include "RWMAKE.ch"

/*
===============================================================================================================================
Programa----------: DL200TRB
Autor-------------: Wodson Reis Silva
Data da Criacao---: 03/08/2009  
Descrição---------: Ponto de Entrada na gravacao do arquivo temporario da Montagem de Carga. 
------------------: Apos a inclusao dos campos que irao gerar a estrutura do arquivo temporario de pedidos na montagem de carga
------------------: Os campos adicionais deverao ter suas caracteristicas (Ver DL200BRW) e suas respectivas               	   
------------------: gravacoes (ver OM200GRV).
Parametros--------: ParamIXB
Retorno-----------: aRet
===============================================================================================================================*/
User Function DL200TRB()

Local aRet     := ParamIXB
Local aCpos    := {} //{"C5_I_EST  ","C5_I_CMUN ","C5_I_GRPVE","C5_I_OBPED","C5_VEND1  ","C5_VEND2  "}
Local nX       := 0
Local aArea    := FWGetArea()
Local aAreaSX3 := SX3->(GetArea())
Local _cCpoDAI := ""
Local _nPosTraco

//Arrays de controle dos campos que deverao ser mostrados no Grid da rotina de Montagem de Carga.
aCpos := AllTrim(GetMv("IT_CMPCARG"))
aCpos := If(Empty(aCpos),{},&aCpos)
aAdd(aCpos,"DAI_I_FROL")//Chamado 49894. Só preciso desse campo na estrutura do arquivo temporário, não precisa dele no 1o browse de montagem de carga.
For nX := 1 To Len(aCpos)
    
    DBSelectArea("SX3")
    DBSetOrder(2)//X3_CAMPO
    If DBSeek(aCpos[nX])
        //Tratamento para que o nome do campo nao exceda 10 digitos.
        _ccampo := Getsx3cache(aCpos[nX],"X3_CAMPO") 
        
        _atam := TamSX3(_ccampo)
        _ntamanho := _atam[1]
        _ndecimal := _atam[2]
        _ctipo := _atam[3]

        _nPosTraco := At("_",_ccampo)
        If _nPosTraco == 0
        _nPosTraco := 3
        EndIf

        If Len("PED"+SubStr(_ccampo,_nPosTraco,Len(AllTrim(_ccampo))-2)) > 10
           aAdd(aRet,{"PED"+SubStr(_ccampo,_nPosTraco,7),_ctipo,_ntamanho,_ndecimal})
        Else
           aAdd(aRet,{"PED"+SubStr(_ccampo,_nPosTraco,Len(AllTrim(_ccampo))-2),_ctipo,_ntamanho,_ndecimal})
        EndIf

        _cCpoDAI += aRet[Len(aRet),1]+", "
    Else
        U_ITMsg("O campo "+AllTrim(aCpos[nX])+" informado no parametro IT_CMPCARG, nao existe.","Campo Inexistente",;
                "Cadastre o mesmo atraves do modulo Configurador ou retire-o do parametro. "+;
                "Este campo é apresentado no Grid da rotina de Montagem de Carga.",1)
    EndIf
Next nX

FWRestArea(aArea)
FWRestArea(aAreaSX3)
Return aRet
