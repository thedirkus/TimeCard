PFont font_title;
PFont font_time;

float timer;
int start_day;
int start_month;
int start_year;

boolean running;
Button start;
Button checkin;

// Internal Variables 
ArrayList<String> pastdatevalues;
int hourstoday;
boolean hastoday;
boolean saved;

String[] monthname = {"Jan", "Feb", "Mar", "Apr",
                      "May", "Jun", "Jul", "Aug",
                      "Sep", "Oct", "Nov", "Dec"};

// CONSTANTS
public static String TEMPFILE = "~timeytemp.txt";


/**********************************************************************
    SETUP
 **********************************************************************/
 
void setup() {
        
    // Flush the temp file
    // called TEMPFILE
    try { flushTempFile(); } catch (IOException e) { }
    
    // Window Setup
    size(300,400);
    
    // Fonts
    font_title = createFont("Arial",48,true);
    font_time = createFont("Times New Roman",48,true);
    
    
    // Program Variables
    running = false;
    buildup = 0;
    prev_min = minute();
    timer = 0;
    
    
    // Graphical Setup
    start = new Button(150,200,100,32,"Start");
    start.setFill(50,200,50);
    start.setStroke(0,100,0);
}

/**********************************************************************
    DRAW
 **********************************************************************/

void draw() {
    background(255,255,180);
    
    //title
    textFont(font_title,48);
    fill(0,50,100);
    textAlign(LEFT);
    text("TiMe",20,50);
    
    //time
    textFont(font_time,48);
    fill(0);
    textAlign(CENTER);
    
    int hou;
    String ampm;
    if(hour() == 0) {
        hou = 12;
        ampm = "am";
    } else if (hour() > 12) {
        hou = hour() - 12;
        ampm = "pm";
    } else {
        hou = hour();
        ampm = "am";
        if (hour() == 12)
            ampm = "pm";
    }
    
    int mino = minute();
    String mins;
    if( mino < 10 ) {
        mins = "0" + mino;
    } else {
        mins = "" + mino;
    }
    
    text( hou + ":" + mins + " " + ampm, 150,150);
    
    //start and stop
    start.draw();
    if(start.isPressed()) {
        if(running) {
            start.setFill(50,200,50);
            start.setStroke(0,100,0);
            start.setText("Start");
        } else {
            start.setFill(200,50,50);
            start.setStroke(100,0,0);
            start.setText("Stop");
            
            start_day = day();
            start_month = month();
            start_year = year();
        }
    }
    

    if(running) {
        dayRollover();
        updateTimer();
    }
}

/**********************************************************************
    SAVING AND DISPOSE
 **********************************************************************/

void saveTime() throws IOException{
    BufferedReader tmpreader = createReader(TEMPFILE);
    int thishours = 0;
    if(tmpreader != null) {
        tmpreader = createReader(TEMPFILE);
        // month/year/day/hours
        String read = tmpreader.readLine();
        if(read != null) {
            String[] tempdata = split(read,"/");
            tmpreader.close();
            int thisday = int(tempdata[2]);
            if(thisday != day()) {
                flushTempFile();
                tmpreader = createReader(TEMPFILE);
                tempdata = split(tmpreader.readLine(),"/");
            }
            thishours = int(tempdata[3]);  
        }
    }
    
    // add timer to hours
    thishours += timer;
    
    // timer resets
    timer = 0;
    
    // overwrite with new hours
    PrintWriter tmpwriter = createWriter(TEMPFILE);
    tmpwriter.println(monthname[start_month] + "/" + start_year + "/" + start_day + "/" + thishours);
    saved = true;
}

void dispose() {
    if(!saved) {
        try { saveTime(); } catch (IOException e) { }
    }
    try { flushTempFile(); } catch (IOException e) { }
}

// upon a day rollover, flushes tempdata and starts writing new days
// will update start_day
void dayRollover() {
    // rollover on this condition
    if(start_day != day()) {
        // save and flush
        try { saveTime(); } catch (IOException e) { }
        try { flushTempFile(); } catch (IOException e) { }
        start_day = day();
        start_month = month();
        start_year = year();
    }
}

/**********************************************************************
    RUNTIME FUNCTIONS
 **********************************************************************/

int prev_min;
int buildup;

void updateTimer() {
    int m = minute();
    
    int mdif = m-prev_min;
    
    if(mdif > 0) {
        buildup += mdif;
    } else if (mdif < 0) {
        buildup += (m+60-prev_min);
    }
    
    if(buildup >= 6) {
        timer += 0.1;
        buildup -= 6;
        saved = false;
    }
    
    prev_min = m;
}

void mouseReleased() {
       if(mouseX >= 100
          && mouseX <= 200
          && mouseY >= 185
          && mouseY <= 215) {
           if(running) {
               running = false;
           } else {
               running = true;
           }
       }
}



/**********************************************************************
    FILE PARSING
 **********************************************************************/

// Flush single temp file
// Results in a new temp file with today's current value
void flushTempFile() throws IOException {
    // Check for temp file
    BufferedReader tmpreader = createReader(TEMPFILE);
    ArrayList<String> tmpvals = new ArrayList<String>();
    if(tmpreader != null) {
        filetolist(tmpreader,tmpvals);
        tmpreader.close();
    }
    
    // save today's hours
    float todayhours = -1;
    
    // For Each TMP entry, check for monthly file then do the full parse
    for(int tmpi = 0; tmpi < tmpvals.size(); tmpi++) {
        String[] splittmpval = split(tmpvals.get(tmpi),"/");
        String moyr = splittmpval[0] + splittmpval[1] + ".txt";
        // save today's hours
        if( int(splittmpval[2]) == day() )
            todayhours = float(splittmpval[3]);
        String sf0 = findSavedFile(moyr);
        // If null, create the new saved file to flush the temp data
        if(sf0 == null) {
            createNewFile(tmpvals.get(tmpi));
        // Otherwise, add to file
        } else {
            addToFile(sf0, tmpvals.get(tmpi));
        }
    }
    
    if(todayhours > -1) {
        PrintWriter pw1 = createWriter(TEMPFILE);
        pw1.println(monthname[month()] + "/" + year() + "/" + day() + "/" + todayhours);
        pw1.flush();
        pw1.close();
    } 
}

String findSavedFile(String moyr) {
    String[] moyrvals = split(moyr,"/");
    String filename = moyrvals[0] + moyrvals[1] + ".txt";
    
    BufferedReader bf1 = createReader(filename);
    if(bf1 == null) {
        return null;
    } else {
        try { bf1.close(); } catch (IOException e) { }
        return filename;
    }
}

void createNewFile(String value) {
    String[] splitval = split(value,"/");
    String file =  splitval[0] + splitval[1] + ".txt";
    PrintWriter pw = createWriter(file);
    pw.println(splitval[2] + "/" + splitval[3]);
    pw.flush();
    pw.close();
}

void addToFile(String sf0, String value) {
    BufferedReader reader0 = createReader(sf0);
    ArrayList<String> sfdata = new ArrayList<String>();
    filetolist(reader0,sfdata);
    
    int vday = int(split(value,"/")[2]);
    int vhrs = int(split(value,"/")[3]);
    int prevday = -1;
    
    String data;
    int dataday;
    int datahrs;
    
    // Search for the day
    for(int i = 0; i < sfdata.size(); i++) {
        data = sfdata.get(i);
        dataday = int(split(data,"/")[0]);
        datahrs = int(split(data,"/")[1]);
        // if day found and hours don't match, update entry
        if(vday == dataday) {
            if(vhrs != datahrs) {
                sfdata.set(i,value);
            }
            // break because date found
            break;
        // if day is not found, but must be added
        } else if (vday < dataday && vday > prevday) {
            sfdata.add(i,value);
            break;
        }
        prevday = dataday;
    }
    PrintWriter pw0 = createWriter(sf0);
    listtofile(sfdata,pw0);
    try { reader0.close(); } catch (IOException e) { }
    pw0.flush();
    pw0.close();
}

/*
 * Reads a file's contents, line by line, into an ArrayList
 * Does not guarantee to read from start of file
 */
void filetolist(BufferedReader r, ArrayList<String> al) {
    try {
        String curline = r.readLine();
        while(curline != null) {
            al.add(curline);
            r.readLine();
        }
    } catch (IOException e) { }
}

void listtofile(ArrayList<String> al, PrintWriter pr) {
    for(int i = 0; i < al.size(); i++) {
        pr.println(al.get(i));
    }
    pr.flush();
}





/**********************************************************************
    CLASSES
 **********************************************************************/

class Button {
    
    int x, y, w, h;
    int rf,gf,bf,rs,gs,bs;
    String text;
    PFont f;
    int fontsize;
    boolean clicked;
    
    public Button(int x_,int y_, int w_, int h_, String t) {
        x = x_;
        y = y_;
        w = w_;
        h = h_;
        rf = 0;
        gf = 0;
        bf = 0;
        rs = 0;
        gs = 0;
        bs = 0;
        text = t;
        f = createFont("Arial",48,true);
        fontsize = 32;
        clicked = false;
    }
    
    public void draw() {
        
        if(mousePressed &&
            mouseX >= x-(w/2) &&
            mouseX <= x+(w/2) &&
            mouseY <= y+(h/2) &&
            mouseY >= y-(h/2)) {
                
            clicked = true;
            int rl = rf + 50;
            if(rl > 255)
                rl = 255;
                
            int gl = gf + 50;
            if(gl > 255)
                gl = 255;
                
            int bl = bf + 50;
            if(bl > 255)
                bl = 255;
                
            fill(rl,gl,bl);
        } else {
            fill(rf,gf,bf);
            clicked = false;
        }
        
        stroke(rs,gs,bs);
        rectMode(CENTER);
        rect(x,y,w,h);

        textFont(f,fontsize);
        fill(0);
        textAlign(CENTER);
        text(text,x,y+(h/2)-2);
    }
    
    public boolean isPressed() {
        return clicked;
    }
    
    public void setText(String t) {
        text = t;
    }
    
    public void setFontSize(int fs) {
        fontsize = fs;
    }
    
    public void setFill(int r, int g, int b) {
        rf = r; gf = g; bf = b;
    }
    
    public void setStroke(int r, int g, int b) {
        rs = r; gs = g; bs = b;
    }
    
};
