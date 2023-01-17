Sub Main

	Dim prj As PslProject
	Dim srclst As PslSourceList
	Dim srclsts As PslSourceLists
	Dim srcstr As PslSourceString
	Dim trgtlsts As PslTransLists
	Dim trgtlst As PslTransList


	Set prj = PSL.ActiveProject
	Set srclsts = prj.SourceLists

	For Each srclst In srclsts
    	If InStr(srclst.SourceFile, "helius") <> 0 Then
        Else
				prj.SourceLists.Remove(srclst)

    	End If

	Next srclst


End Sub
