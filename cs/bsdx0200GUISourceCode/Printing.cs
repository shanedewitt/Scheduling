﻿using System;
using System.Drawing.Printing;
using System.Drawing;
using System.Text;
using System.Drawing.Drawing2D;
using System.Linq;
using System.Data;

namespace IndianHealthService.ClinicalScheduling
{
    public class Printing
    { 
        /// <summary>
        /// Print Appointments
        /// </summary>
        /// <param name="ds">Strongly Typed DataSet contains Resources and Appointments</param>
        /// <param name="e">PrintPageEventArgs from PrintDocument Print handler</param>
        /// <param name="beg">Begin Datetime to print appointments</param>
        /// <param name="end">End Datetime to print appointments</param
        /// <param name="resourceToPrint">The resouce to print</param>
        /// <param name="apptPrinting">Current Appointment printing</param>
        /// <param name="pageNumber">Current page number</param>
        /// <remarks>beg and end have no effect on operation--they are there for documentation for user only</remarks>
        public virtual void PrintAppointments(dsPatientApptDisplay2 ds, PrintPageEventArgs e, DateTime beg, DateTime end, int resourceToPrint, ref int apptPrinting, int pageNumber)
        {
            Graphics g = e.Graphics;
            //g.PageUnit = GraphicsUnit.Millimeter;
            //SizeF szVCB = g.VisibleClipBounds.Size;
            //PointF[] ptszVCB = {new PointF(szVCB.Width,szVCB.Height)};
            //g.TransformPoints(CoordinateSpace.Page, CoordinateSpace.Device, ptszVCB);
            //Create Fonts
            Font f8 = new Font(FontFamily.GenericSerif, 8);
            Font f10 = new Font(FontFamily.GenericSerif, 10);
            Font f14bold = new Font(FontFamily.GenericSerif, 14, FontStyle.Bold);
            
            //Center Alignment for some stuff
            StringFormat sf = new StringFormat();
            sf.Alignment = StringAlignment.Center;
            
            //Header
            g.DrawString("Confidential Patient Information", f8, Brushes.Black, e.PageBounds, sf);
            
            //Footer
            sf.Alignment = StringAlignment.Center;
            sf.LineAlignment = StringAlignment.Far;
            g.DrawString("Page " + pageNumber, f8, Brushes.Black, e.PageBounds, sf);

            //Typical manipulable print area
            Rectangle printArea = e.MarginBounds;
            
            //resource we want to print
            dsPatientApptDisplay2.BSDXResourceRow r = ds.BSDXResource[resourceToPrint];
            
            //header
            string toprint;
            if (beg == end) toprint = "Appointments for " + r.RESOURCE_NAME + " on " + beg.ToLongDateString();
            else toprint = "Appointments for " + r.RESOURCE_NAME + " from " + beg.ToShortDateString() + " to "
                + end.ToShortDateString();
            g.DrawString(toprint, f14bold, Brushes.Black, printArea);
            
            //Move print area down
            printArea.Height -= (int)f14bold.GetHeight();
            printArea.Y += (int)f14bold.GetHeight();

            //Draw Line
            g.DrawLine(new Pen(Brushes.Black, 0), printArea.X, printArea.Y, printArea.X + printArea.Width, printArea.Y);
            
            //Move print area down
            printArea.Y += 5; 
            printArea.Height -= 5;
            
            System.Data.DataRow[] appts = r.GetChildRows(ds.Relations[0]); //ds has only one relation 

            StringFormat sf2 = new StringFormat();                 //sf to hold tab stops
            sf2.SetTabStops(50, new float[] { 100, 250, 25 });     

            //appt printed starts at zero
            while (apptPrinting < appts.Length)
            {
                dsPatientApptDisplay2.PatientApptsRow a = (dsPatientApptDisplay2.PatientApptsRow)appts[apptPrinting];
                
                StringBuilder apptPrintStr = new StringBuilder(200); 
                apptPrintStr.AppendLine(a.ApptDate.ToString() + "\t" + a.Name + " (" + a.Sex + ")" + "\t" + "DOB: " + a.DOB.ToShortDateString() + "\t" + "ID: " + a.HRN);
                apptPrintStr.AppendLine("P: " + a.HOMEPHONE + "\t" + "Address: " + a.STREET + ", " + a.CITY + ", " + a.STATE + " " + a.ZIP);
                apptPrintStr.AppendLine("Note: " + a.NOTE);
                apptPrintStr.AppendLine("Appointment made by " + a.APPT_MADE_BY + " on " + a.DATE_APPT_MADE);

                int printedApptHeight = (int)g.MeasureString(apptPrintStr.ToString(), f10, printArea.Width).Height;
                if (printedApptHeight > printArea.Height) // too much to print -- move to next page
                    // but don't increment the appointment to print since we haven't printed it yet.
                    // i.e. apptPrinting stays the same.
                {
                    e.HasMorePages = true;
                    break;
                }
   
                //otherwise print it
                g.DrawString(apptPrintStr.ToString(), f10, Brushes.Black, printArea, sf2);
                
                //Move print area down
                printArea.Y += printedApptHeight + 3;
                printArea.Height -= printedApptHeight + 3;

                //Draw a divider line
                Point pt1 = new Point((int)(printArea.X + printArea.Width * 0.25), printArea.Y);
                Point pt2 = new Point((int)(printArea.X + printArea.Width * 0.75), printArea.Y);
                g.DrawLine(Pens.Gray, pt1, pt2);

                //move down, again
                printArea.Y += 3;
                printArea.Height -= 3;

                //go to the next appointment
                apptPrinting++;
            }
        }

        /// <summary>
        /// Prints a single appointment slip to give to the patient
        /// </summary>
        /// <param name="appt">The Appointment to print</param>
        /// <param name="e">PrintPageEventArgs from PrintDocument Print handler</param>
        public virtual void PrintAppointmentSlip(CGAppointment appt, PrintPageEventArgs e)
        {
            // Prep
            Graphics g = e.Graphics;
            Rectangle printArea = e.MarginBounds;
            Rectangle pageArea = e.PageBounds;
            Rectangle headerArea = new Rectangle()
            {
                X = e.MarginBounds.X,
                Y = e.PageBounds.Y,
                Height = e.MarginBounds.Y - e.PageBounds.Y,
                Width = e.MarginBounds.Width
            };

            // A few fonts
            Font fTitle = new Font(FontFamily.GenericSerif, 24, FontStyle.Bold); //for title
            Font fBody = new Font(FontFamily.GenericSerif, 12);
            Font fGroupTitle = new Font(FontFamily.GenericSansSerif, 10, FontStyle.Bold);

            StringFormat sf0 = new StringFormat()
            {
                 Alignment = StringAlignment.Center,
                 LineAlignment = StringAlignment.Center
            };
            
            // Draw Header
            string division = CGDocumentManager.Current.ConnectInfo.DivisionName;
            g.DrawString(division, fBody, Brushes.Black, headerArea, sf0);
            
            // Draw Title
            StringFormat sf = new StringFormat();
            sf.Alignment = StringAlignment.Center; //for title & header

            string s = "Appointment Reminder Slip";
            g.DrawString(s, fTitle, Brushes.Black, printArea, sf); //title

            // move down
            int titleHeight = (int)g.MeasureString(s, fTitle, printArea.Width).Height;
            printArea.Y += titleHeight;
            printArea.Height -= titleHeight;

            // draw underline
            g.DrawLine(Pens.Black, printArea.Location, new Point(printArea.Right, printArea.Y));
            printArea.Y += 15;
            printArea.Height -= 15;

            // draw curved rectangle.
            Rectangle personalInfoRectangle = new Rectangle(e.MarginBounds.X, printArea.Y + 30, 280, 300);
            using (GraphicsPath path = GetRoundedRectPath(personalInfoRectangle, 10))
            {
                g.DrawPath(Pens.Black, path);
            }

            // group header
            g.DrawString("Patient Information", fGroupTitle, Brushes.Black, new Point(personalInfoRectangle.X, personalInfoRectangle.Y - 20));
            
            // inner rectangle for drawing strings:
            Rectangle personalInfoInnerRectangle = new Rectangle(personalInfoRectangle.X + 20, personalInfoRectangle.Y + 20, 280 - 40, 300 - 40);
            
            // Strings to write
            StringBuilder sb = new StringBuilder(500);
            sb.AppendLine("Name:" + "\t" + appt.Patient.Name);
            sb.AppendLine();
            sb.AppendLine("ID#:" + "\t" + appt.Patient.ID);
            sb.AppendLine();
            sb.AppendLine("DOB:" + "\t" + appt.Patient.DOB.ToShortDateString());
            sb.AppendLine();
            sb.AppendLine("Age:" + "\t" + appt.Patient.UserFriendlyAge);
            sb.AppendLine();
            sb.AppendLine("Sex:" + "\t" + appt.Patient.Sex.ToString());
            
            // Draw them
            g.DrawString(sb.ToString(), fBody, Brushes.Black, personalInfoInnerRectangle);

            // draw curved rectangle
            Rectangle apptInfoRectangle = new Rectangle(e.MarginBounds.X + e.MarginBounds.Width - 280, printArea.Y + 30, 280, 300);
            using (GraphicsPath path = GetRoundedRectPath(apptInfoRectangle, 10))
            {
                g.DrawPath(Pens.Black, path);
            }

            // group header
            g.DrawString("Appointment Information", fGroupTitle, Brushes.Black, new Point(apptInfoRectangle.X, apptInfoRectangle.Y - 20));

            // Strings to write
            sb = new StringBuilder();
            sb.AppendLine("Clinic: " + "\t" + appt.Resource);
            sb.AppendLine();
            sb.AppendLine("Date: " + "\t" + appt.StartTime.ToShortDateString());
            sb.AppendLine();
            sb.AppendLine("Day: " + "\t" + appt.StartTime.DayOfWeek.ToString());
            sb.AppendLine();
            sb.AppendLine("Time: " + "\t" + appt.StartTime.ToShortTimeString());

            // Draw them
            Rectangle apptInfoInnerRectangle = new Rectangle(apptInfoRectangle.X + 20, apptInfoRectangle.Y + 20, 280 - 40, 300 - 40);

            // Draw them
            g.DrawString(sb.ToString(), fBody, Brushes.Black, apptInfoInnerRectangle);

            // Move Drawing Rectangle Down
            printArea.Y += 300 + 30 + 20;
            printArea.Height -= 300 + 30 + 20;

            // Draw New Line
            g.DrawLine(Pens.Black, printArea.Location, new Point(printArea.Right, printArea.Y));
            printArea.Y += 5;
            printArea.Height -= 5;

            // Draw new Title
            s = "Clinic Instructions";
            g.DrawString(s, fTitle, Brushes.Black, printArea, sf); //title

            // move down
            titleHeight = (int)g.MeasureString(s, fTitle, printArea.Width).Height;
            printArea.Y += titleHeight;
            printArea.Height -= titleHeight;

            // Draw New Line
            g.DrawLine(Pens.Black, printArea.Location, new Point(printArea.Right, printArea.Y));
            printArea.Y += 15;
            printArea.Height -= 15;

            // Get Resource Clinic Appointment Letter Text
            DataTable resources = CGDocumentManager.Current.GlobalDataSet.Tables["Resources"];

            string ltrTxt = (from resource in resources.AsEnumerable()
                             where resource.Field<string>("RESOURCE_NAME") == appt.Resource
                             select resource.Field<string>("LETTER_TEXT")).SingleOrDefault<string>();

            if (String.IsNullOrWhiteSpace(ltrTxt)) ltrTxt = "(no instructions provided)";

            g.DrawString(ltrTxt, fBody, Brushes.Black, printArea);

            int ltrTxtHeight = (int)g.MeasureString(ltrTxt, fBody).Height;

            printArea.Y += ltrTxtHeight + 15;
            printArea.Height -= ltrTxtHeight + 15;

            g.DrawLine(Pens.Black, printArea.Location, new Point(printArea.Right, printArea.Y));
            printArea.Y += 5;
            printArea.Height -= 5;

            s = "Notes";
            g.DrawString(s, fTitle, Brushes.Black, printArea, sf); // Notes title
            
            // move down
            titleHeight = (int)g.MeasureString(s, fTitle, printArea.Width).Height;
            printArea.Y += titleHeight;
            printArea.Height -= titleHeight;

            // Draw New Line
            g.DrawLine(Pens.Black, printArea.Location, new Point(printArea.Right, printArea.Y));
            printArea.Y += 15;
            printArea.Height -= 15;

            // Draw Notes Area
            using (GraphicsPath path = GetRoundedRectPath(printArea, 15))
            {
                g.DrawPath(Pens.Black, path);
            }

            // Draw Footer
            // Get footer rectangle
            Rectangle footerArea = new Rectangle()
            {
                X = e.MarginBounds.X,
                Y = e.MarginBounds.Height + headerArea.Height,
                Width = e.MarginBounds.Width,
                Height = pageArea.Height - (e.MarginBounds.Height + headerArea.Height)
            };

            //use sf0 to print the footer (center all the way)
            s = "Printed: " + DateTime.Now.ToString();
            Font fFooter = new Font(FontFamily.GenericSerif, 7);
            g.DrawString(s, fFooter, Brushes.Black, footerArea, sf0);

        }


        private GraphicsPath GetRoundedRectPath(Rectangle rect, int radius)
        {
            int diameter = 2 * radius;
           
            Rectangle arcRect = new Rectangle(rect.Location, new Size(diameter, diameter));
            GraphicsPath path = new GraphicsPath();
            
            path.AddArc(arcRect, 180, 90); //top left
            arcRect.X = rect.Right - diameter;
            path.AddArc(arcRect, 270, 90); // top right
            arcRect.Y = rect.Bottom - diameter;
            path.AddArc(arcRect, 0, 90); // bottom right
            arcRect.X = rect.Left;
            path.AddArc(arcRect, 90, 90); // bottom left

            path.CloseFigure();

            return path;
        }

        /// <summary>
        /// Print Letter to be given or mailed to the patient
        /// </summary>
        /// <param name="ptrow">Strongly typed PatientApptsRow to pass (just one ApptRow)</param>
        /// <param name="e">You know what that is</param>
        /// <param name="letter">Contains letter string</param>
        /// <param name="title">Title of the letter</param>
        public virtual void PrintReminderLetter(dsPatientApptDisplay2.PatientApptsRow ptRow, PrintPageEventArgs e, string letter, string title)
        {

            Rectangle printArea = e.MarginBounds;
            Graphics g = e.Graphics;
            StringFormat sf = new StringFormat();
            sf.Alignment = StringAlignment.Center; //for title
            Font fTitle = new Font(FontFamily.GenericSerif, 24, FontStyle.Bold); //for title
            Font fBody = new Font(FontFamily.GenericSerif, 12);
            g.DrawString(title, fTitle, Brushes.Black, printArea, sf); //title

            // move down
            int titleHeight = (int)g.MeasureString(title, fTitle, printArea.Width).Height;
            printArea.Y += titleHeight;
            printArea.Height -= titleHeight;
            
            // draw underline
            g.DrawLine(Pens.Black, printArea.Location, new Point(printArea.Right, printArea.Y));
            printArea.Y += 15;
            printArea.Height -= 15;

            // write appointment date
            string str = "Appointment Date: " + ptRow.ApptDate + "\n\n";
            g.DrawString(str, fBody, Brushes.Black, printArea);

            // move down
            int strHeight = (int)g.MeasureString(str, fBody, printArea.Width).Height;
            printArea.Y += strHeight;
            printArea.Height -= strHeight;

            //Text Direction
            StringFormat sf2 = new StringFormat();
            if (System.Threading.Thread.CurrentThread.CurrentCulture.TextInfo.IsRightToLeft)
                sf2.FormatFlags = StringFormatFlags.DirectionRightToLeft;

            // write missive
            g.DrawString(letter, fBody, Brushes.Black, printArea, sf2);

            //print Address in lower left corner for windowed envolopes
            printArea.Location = new Point(e.MarginBounds.X, (int)(e.PageBounds.Height * 0.66));
            printArea.Height = (int)(e.MarginBounds.Height * 0.20);
            sf.Alignment = StringAlignment.Near;
            sf.LineAlignment = StringAlignment.Center;
            StringBuilder address = new StringBuilder(100);
            address.AppendLine(ptRow.Name);
            address.AppendLine(ptRow.STREET);
            address.AppendLine(ptRow.CITY + ", " + ptRow.STATE + " " + ptRow.ZIP);
            g.DrawString(address.ToString(), fBody, Brushes.Black, printArea, sf);
        }
       
        /// <summary>
        /// Cancellation Letter to be given or mailed to the patient
        /// </summary>
        /// <param name="ptRow">Strongly typed PatientApptsRow to pass (just one ApptRow)</param>
        /// <param name="e">You know what that is</param>
        /// <param name="letter">Contains letter string</param>
        /// <param name="title">Title of the letter</param>
        public virtual void PrintCancelLetter(dsRebookAppts.PatientApptsRow ptRow, PrintPageEventArgs e, string letter, string title)
        {
            Rectangle printArea = e.MarginBounds;
            Graphics g = e.Graphics;
            StringFormat sf = new StringFormat();
            sf.Alignment = StringAlignment.Center; //for title
            Font fTitle = new Font(FontFamily.GenericSerif, 24, FontStyle.Bold); //for title
            Font fBody = new Font(FontFamily.GenericSerif, 12);
            g.DrawString(title, fTitle, Brushes.Black, printArea, sf); //title

            // move down
            int titleHeight = (int)g.MeasureString(title, fTitle, printArea.Width).Height;
            printArea.Y += titleHeight;
            printArea.Height -= titleHeight;

            // draw underline
            g.DrawLine(Pens.Black, printArea.Location, new Point(printArea.Right, printArea.Y));
            printArea.Y += 15;
            printArea.Height -= 15;

            // write appointment date
            string str = "Appointment Date: " + ptRow.OldApptDate + "\n\n";
            g.DrawString(str, fBody, Brushes.Black, printArea);

            // move down
            int strHeight = (int)g.MeasureString(str, fBody, printArea.Width).Height;
            printArea.Y += strHeight;
            printArea.Height -= strHeight;

            //Text Direction
            StringFormat sf2 = new StringFormat();
            if (System.Threading.Thread.CurrentThread.CurrentCulture.TextInfo.IsRightToLeft)
                sf2.FormatFlags = StringFormatFlags.DirectionRightToLeft;
            
            // write missive
            g.DrawString(letter, fBody, Brushes.Black, printArea, sf2);

            //print Address in lower left corner for windowed envolopes
            printArea.Location = new Point(e.MarginBounds.X, (int)(e.PageBounds.Height * 0.66));
            printArea.Height = (int)(e.MarginBounds.Height * 0.20);
            sf.Alignment = StringAlignment.Near;
            sf.LineAlignment = StringAlignment.Center;
            StringBuilder address = new StringBuilder(100);
            address.AppendLine(ptRow.Name);
            address.AppendLine(ptRow.STREET);
            address.AppendLine(ptRow.CITY + ", " + ptRow.STATE + " " + ptRow.ZIP);
            g.DrawString(address.ToString(), fBody, Brushes.Black, printArea, sf);
        }

        /// <summary>
        /// Print rebook letters. Prints old and new appointments dates then the missive.
        /// </summary>
        /// <param name="ptRow">Strongly typed appointment row</param>
        /// <param name="e">etc</param>
        /// <param name="letter">Text of the letter to print</param>
        /// <param name="title">Title to print at the top of the letter</param>
        public virtual void PrintRebookLetter(dsRebookAppts.PatientApptsRow ptRow, PrintPageEventArgs e, string letter, string title)
        {
            Rectangle printArea = e.MarginBounds;
            Graphics g = e.Graphics;
            StringFormat sf = new StringFormat();
            sf.Alignment = StringAlignment.Center; //for title
            Font fTitle = new Font(FontFamily.GenericSerif, 24, FontStyle.Bold); //for title
            Font fBody = new Font(FontFamily.GenericSerif, 12);
            g.DrawString(title, fTitle, Brushes.Black, printArea, sf); //title

            // move down
            int titleHeight = (int)g.MeasureString(title, fTitle, printArea.Width).Height;
            printArea.Y += titleHeight;
            printArea.Height -= titleHeight;

            // draw underline
            g.DrawLine(Pens.Black, printArea.Location, new Point(printArea.Right, printArea.Y));
            printArea.Y += 15;
            printArea.Height -= 15;

            // write old and new appointment dates
            string str = "Old Appointment Date:\t\t" + ptRow.OldApptDate + "\n";
            str += "New Appointment Date:\t\t" + ptRow.NewApptDate + "\n\n";
            g.DrawString(str, fBody, Brushes.Black, printArea);

            // move down
            int strHeight = (int)g.MeasureString(str, fBody, printArea.Width).Height;
            printArea.Y += strHeight;
            printArea.Height -= strHeight;

            //Text Direction
            StringFormat sf2 = new StringFormat();
            if (System.Threading.Thread.CurrentThread.CurrentCulture.TextInfo.IsRightToLeft)
                sf2.FormatFlags = StringFormatFlags.DirectionRightToLeft;

            // write missive
            g.DrawString(letter, fBody, Brushes.Black, printArea, sf2);

            //print Address in lower left corner for windowed envolopes
            printArea.Location = new Point(e.MarginBounds.X, (int)(e.PageBounds.Height * 0.66));
            printArea.Height = (int)(e.MarginBounds.Height * 0.20);
            sf.Alignment = StringAlignment.Near;
            sf.LineAlignment = StringAlignment.Center;
            StringBuilder address = new StringBuilder(100);
            address.AppendLine(ptRow.Name);
            address.AppendLine(ptRow.STREET);
            address.AppendLine(ptRow.CITY + ", " + ptRow.STATE + " " + ptRow.ZIP);
            g.DrawString(address.ToString(), fBody, Brushes.Black, printArea, sf);

        }

        /// <summary>
        /// Print message on a page; typically that there are no appointments to be found.
        /// Or just a test message to verify that printing works.
        /// </summary>
        /// <param name="msg">The exact string to print.</param>
        /// <param name="e">Print Page event args</param>
        public virtual void PrintMessage(string msg, PrintPageEventArgs e)
        {
            e.Graphics.DrawString(msg, new Font(FontFamily.GenericSerif, 14),
                Brushes.Black, e.MarginBounds);
        }

        /// <summary>
        /// Print Routing Slip
        /// </summary>
        /// <param name="a">Appointment Data Structure</param>
        /// <param name="title">String to print for title</param>
        /// <param name="e">etc</param>
        public virtual void PrintRoutingSlip(CGAppointment a, string title, PrintPageEventArgs e)
        {
            Rectangle printArea = e.MarginBounds;
            Graphics g = e.Graphics;
            StringFormat sf = new StringFormat();
            sf.Alignment = StringAlignment.Center; //for title
            Font fTitle = new Font(FontFamily.GenericSerif, 24, FontStyle.Bold); //for title
            Font fBody = new Font(FontFamily.GenericSerif, 18);
            Font fBodyEm = new Font(FontFamily.GenericSerif, 18, FontStyle.Bold);
            g.DrawString(title, fTitle, Brushes.Black, printArea, sf); //title

            // move down
            int titleHeight = (int)g.MeasureString(title, fTitle, printArea.Width).Height;
            printArea.Y += titleHeight;
            printArea.Height -= titleHeight;

            // draw underline
            g.DrawLine(Pens.Black, printArea.Location, new Point(printArea.Right, printArea.Y));

            // move down
            printArea.Y += 15;
            printArea.Height -= 15;

            //construct what to print
            string toprint = "Patient: " + a.PatientName + "\t" + "ID: " + a.HealthRecordNumber;
            toprint += "\n\n";
            toprint += "Clinic: " + a.Resource;
            toprint += "\n\n";
            toprint += "Appointment Time: " + a.StartTime;
            toprint += "\n\n";
            toprint += "Notes:\n" + a.Note;

            //print
            g.DrawString(toprint, fBody, Brushes.Black, printArea);

            // Print Date Printed
            //sf to move to bottom center
            StringFormat sf2 = new StringFormat();
            sf2.LineAlignment = StringAlignment.Far;
            sf2.Alignment = StringAlignment.Center;

            //Print
            Font fFooter = new Font(FontFamily.GenericSerif, 8);
            g.DrawString("Printed: " + DateTime.Now, fFooter, Brushes.Black, printArea, sf2);
        }

    }
    public abstract class PrintingCreator
    {
        public abstract Printing PrintFactory();
    }

}