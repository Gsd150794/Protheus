/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |28/10/2024| Chamado 48983. Correção do ERROR.LOG: array out of bounds ( 0 of 74 )  on U_COMCOLSD(COMCOLSD.PRW)
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: COMCOLSD
Autor-----------: Lucas Borges Ferreira
Data da Criacao-: 22/08/2024
Descrição-------: Permite a Verificação dos dados alterados na Tabela SDT após o vínculo de documento. Chamado 48274
Parametros------: ParamIXB[1] -> Array -> aCols SDT
				  ParamIXB[2] -> Array -> aHeader SDT
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function COMCOLSD

Local _aArea    := FwGetArea()
Local _aAreaSDT := SDT->(FwGetArea())
Local _aItens   := ParamIXB[1]
Local _aCab     := ParamIXB[2]
Local _nPosLoc  := aScan(_aCab,{|x|AllTrim(x[2]) == "DT_LOCAL"})
Local _nPosItem := aScan(_aCab,{|x|AllTrim(x[2]) == "DT_ITEM"})
Local _nI       := 0

SDT->(DBSetOrder(3))
If _nPosLoc > 0 .And. _nPosItem > 0 .And. SDT->(DBSeek(SDS->(DS_FILIAL+DS_FORNEC+DS_LOJA+DS_DOC+DS_SERIE)))
    While !SDT->(Eof()) .And. SDT->(DT_FILIAL+DT_FORNEC+DT_LOJA+DT_DOC+DT_SERIE) == SDS->(DS_FILIAL+DS_FORNEC+DS_LOJA+DS_DOC+DS_SERIE)
        For _nI := 1 To Len( _aItens )
            If SDT->DT_ITEM == _aItens[_nI][_nPosItem] .And. SDT->DT_LOCAL <> _aItens[_nI][_nPosLoc]
                RecLock("SDT",.F.)
                SDT->DT_LOCAL := _aItens[_nI][_nPosLoc]
                SDT->(MSUnLock())
            EndIf
        Next _nI
        SDT-> (DBSkip())
    EndDo
EndIf

SDT->(FwRestArea(_aAreaSDT))
FwRestArea(_aArea)

Return
