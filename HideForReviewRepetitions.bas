' Hide all repetitions marked as for-review. Based on manage_repetitions macro, but result of this macro cannot be reversed


Function LockTagRepeated

	start_time = Timer()

	Set d = CreateObject("Scripting.Dictionary")

	Dim prj As PslProject
	Dim srclst As PslSourceList
	Dim trnlst As PslTransList
	Dim  i, j, arrcount As Long
	Dim TrnSrcStrngs() As Variant
	Dim trans_str As PslTransString
	Dim id As String
	Dim num_marked_strings As Long
	Dim num_marked_strings_per_translist As Long


	Set prj = PSL.ActiveProject

	arrcount = 0
	num_marked_strings = 0

	prj.SuspendSaving

	For i = 1 To prj.TransLists.Count
		Set trnlst = prj.TransLists(i)
		Set srclst = prj.SourceLists(i)

		num_marked_strings_per_translist = 0

		' for each of the strings in the translation list
		For j = 1 To trnlst.StringCount
			Set trans_str = trnlst.String(j)

			' it's not read only, locked, hidden or translated
			' it's resource is not hidden
			' and there is text in the source
			If trans_str.State(pslStateReadOnly) = False And _
				trans_str.State(pslStateReview) = True And _
				trans_str.State(pslStateHidden) = False And _
				trans_str.State(pslStateLocked) = False And _
				trans_str.Resource.State(pslStateHidden) = False And _
				trans_str.SourceText <> "" Then

				' if the source text is one we have hit already
				id = trnlst.String(j).SourceText + trnlst.String(j).Text

				If d.Exists(id) Then
					' hide it and mark it as a repetion
					srclst.String(j).State(pslStateHidden) = True
					srclst.String(j).Comment = "[REPETITION]"
					num_marked_strings = num_marked_strings + 1
					num_marked_strings_per_translist = num_marked_strings_per_translist + 1
				Else
					' new source string, add it
					d.Add id, arrcount
					arrcount = arrcount + 1
				End If
			End If
		Next j
		srclst.Save

		If num_marked_strings_per_translist <> 0 Then
			trnlst.Update
                                          trnlst.Save
		End If

	Next i

	prj.ResumeSaving
	PSL.Output("Done '" & prj.Name & "' Number of strings marked as repetitions: " & num_marked_strings & " took "& 	Timer() - start_time & " secs")
End Function


Sub Main


'	Clean the Output window
	PSL.OutputWnd.Clear
    LockTagRepeated



End Sub
