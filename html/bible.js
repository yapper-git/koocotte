/*
**	Display note, with a 5 sec timer on lost focus
**
**	Sébastien Koechlin - 2008-01-09 - seb.sword@koocotte.org
*/

// Timer
var displayedTimeout;
var displayedID;

function displayNote(x)
{
	// Remove old
	if( displayedID ) {
		clearTimeout(displayedTimeout);
		displayedID.style.display = "none";
		displayedID = undefined;
	}

	// Display new
	displayedID = document.getElementById(x);
	displayedID.style.display = "block";
}

function hideNote(x)
{
	// Set timer on hide
	displayedTimeout = setTimeout("hideNoteTimer()", 5000);
}

function hideNoteTimer()
{
	displayedID.style.display="none";
	displayedID = undefined;
}
