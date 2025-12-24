#!/usr/bin/env python3
# docker-compose exec backend-flask python3 -m bin.ddb.put_message
import boto3
import sys
from datetime import datetime, timedelta, timezone
import os

attrs = {
  'endpoint_url': os.getenv("AWS_ENDPOINT_URL")
}

if len(sys.argv) == 2:
  if "prod" in sys.argv[1]:
    attrs = {}

def create_message(client,message_group_uuid, created_at, message, sender_uuid, sender_display_name, sender_handle):
  # Entity # Message Group Id
  record = {
    'pk':   {'S': f"MSG#{message_group_uuid}"},
    'sk':   {'S': created_at },
    'data': {'S': message},
    'sender_uuid': {'S': sender_uuid},
    'sender_display_name': {'S': sender_display_name},
    'sender_handle': {'S': sender_handle}
  }
  # insert the record into the table
  table_name = 'webapp-messages'
  response = client.put_item(
    TableName=table_name,
    Item=record
  )
  # print the response
  print(response)

def grg_message(client,timestamp,message):
  sender_uuid = "2aa1c49c-669a-47b0-9177-37efe9e420c4"
  message_group_uuid = "5ae290ed-55d1-47a0-bc6d-fe2bc2700399"

  create_message(
    client=client,
    message_group_uuid= message_group_uuid,
    created_at=timestamp,
    message=message,
    sender_uuid=sender_uuid,
    sender_display_name='Alex Grg',
    sender_handle='alexgrg'
  )

def grigoryev_message(client,timestamp,message):
  sender_uuid = "31634299-187a-4ed9-920f-c119e54074f"
  message_group_uuid = "5ae290ed-55d1-47a0-bc6d-fe2bc2700399"

  create_message(
    client=client,
    message_group_uuid= message_group_uuid,
    created_at=timestamp,
    message=message,
    sender_uuid=sender_uuid,
    sender_display_name='Alexander Grigoryev',
    sender_handle='grigoryev'
  )

dynamodb = boto3.client('dynamodb',**attrs)
now = datetime.now(timezone.utc).astimezone()

conversation = """
Person 1: Have you ever played any of the games from the Mass Effect trilogy? It's one of my favorite gaming series!
Person 2: Yes, I have! I love it too. What's your favorite game in the series?
Person 1: I think my favorite has to be Mass Effect 2. So many great loyalty missions, and the suicide mission at the end is just legendary.
Person 2: Yeah, Mass Effect 2 was peak! I also loved Mass Effect 3, especially the Citadel DLC. It was the perfect farewell to the characters.
Person 1: Agreed, the Citadel DLC was a masterpiece. I was so glad they gave us that final, fun adventure with the whole crew before the end.
Person 2: Definitely. What about your favorite squadmate? Mine is probably Garrus Vakarian.
Person 1: Garrus is amazing! My favorite character is probably Mordin Solus. I loved his fast-paced dialogue and his incredible character arc.
Person 2: Mordin was definitely a standout. I also really loved Liara T'Soni's arc and how she grows from a shy scientist to the Shadow Broker.
Person 1: Liara was amazing too, especially with her role in tracking the Reapers and her relationship with Shepard. Speaking of which, what did you think of the Shepard character?
Person 2: I thought Shepard was a great protagonist. The Paragon/Renegade system made you feel like you were really shaping their personality. And the voice acting was superb.
Person 1: I totally agree! I also really liked the dynamic between Joker and EDI. Those two had some of the funniest lines in the series.
Person 2: Yes! Their interactions were always so witty and charming. And speaking of great scenes, what did you think of the whole Virmire mission?
Person 1: Oh man, that mission was heart-wrenching. It was so well-done, but having to make that choice was one of the hardest things I've ever done in a game.
Person 2: Yeah, it was definitely tough. But it was also one of the moments that cemented the series as something special in my opinion.
Person 1: Absolutely. Mass Effect had so many great moments like that. Do you have a favorite side quest or smaller storyline?
Person 2: Hmm, that's a tough one. I really loved the Shadow Broker mission in Mass Effect 2, but the Grissom Academy mission in 3 was also great. What about you?
Person 1: I think my favorite standalone mission might be Priority: Tuchanka in Mass Effect 3. It had some amazing moments for Mordin and Wrex.
Person 2: Yes, Tuchanka was definitely a standout moment. Mass Effect really had so many great missions and moments throughout its run.
Person 1: Definitely. It's a shame the original trilogy ended, but I'm glad we got the closure we did with the final game.
Person 2: Yeah, despite the controversy, the ending felt earned. It tied up a lot of loose ends and left us with a great sense of the scale of our choices.
Person 1: It really did. Overall, Mass Effect is just such a great series with fantastic characters, writing, and world-building.
Person 2: Agreed. It's one of my favorite sci-fi RPGs of all time and I'm always happy to replay it.
Person 1: Same here. I think one of the things that makes Mass Effect so special is its emphasis on choice and consequence. It's not just a game about shooting aliens, but about the complex relationships you build and the impact of your decisions.
Person 2: Yes, that's definitely one of the series' strengths. And it's not just about big-picture choices, but also about personal relationships and the conversations you have with your crew.
Person 1: Exactly. I love how Mass Effect explores themes of unity, sacrifice, and what it means to be human. Characters like Thane and Legion have such compelling arcs that are driven by their unique perspectives.
Person 2: Yes, the character development in Mass Effect is really top-notch. Even minor characters like Chakwas and Ken Donnelly get their moments to shine and grow over the course of the series.
Person 1: I couldn't agree more. And the way the series handles its lore is so nuanced and thought-provoking. For example, the idea of the Geth and their search for individuality.
Person 2: Yes, that's a really interesting theme to explore. And it's not just a one-dimensional concept, but something that's explored in different contexts with different outcomes.
Person 1: And the series also does a great job of balancing humor and drama. There are so many funny moments on the Normandy, but it never detracts from the serious themes and the high stakes.
Person 2: Absolutely. The humor is always organic and never feels forced. And the series isn't afraid to go dark when it needs to, like in the Overlord DLC or the attack on Earth.
Person 1: Yeah, those parts are definitely tough to play through, but they're also some of the most powerful and memorable moments of the series. And it's not just the writing that's great, but also the voice acting and the art direction.
Person 2: Yes, the voice acting is fantastic across the board. From Mark Meer and Jennifer Hale's performances as Shepard to Keith David's portrayal of Anderson, every actor brings their A-game. And the production design and world-building are really impressive for a game from that era.
Person 1: Definitely. Mass Effect was really ahead of its time in terms of its cinematic presentation and storytelling. And the fact that it was all done within a single, cohesive trilogy makes it even more impressive.
Person 2: Yeah, it's amazing what they were able to accomplish with the narrative they built. It just goes to show how talented the people at BioWare were.
Person 1: Agreed. It's no wonder that Mass Effect has such a devoted fanbase, even all these years later. It's just such a well-crafted and timeless series.
Person 2: Absolutely. I'm glad we can still appreciate it and talk about it all these years later. It really is a series that stands the test of time.
Person 1: One thing I really appreciate about Mass Effect is how it handles diversity. It has a really diverse cast of characters from different species, and it doesn't shy away from exploring issues of prejudice and cultural clashes.
Person 2: Yes, that's a great point. The series was really ahead of its time in terms of its diverse cast and the way it tackled issues like the Krogan genophage or the Quarian-Geth conflict. And it did so in a way that felt natural and integrated into the story.
Person 1: Definitely. It's great to see a game that's not afraid to tackle these issues head-on and address them in a thoughtful and nuanced way. And it's not just about showing prejudice, but also about exploring paths to reconciliation.
Person 2: Yes, the series does a great job of world-building and creating distinct cultures for each of the species. And it's not just about their physical appearance, but also about their history, politics, and values.
Person 1: Absolutely. It's one of the things that sets Mass Effect apart from other sci-fi games. The attention to detail and the thought that went into creating this universe is really impressive.
Person 2: And it's not just the aliens that are well-developed, but also the human factions. The series explores the different ideologies within the Alliance, as well as the more radical groups like Cerberus.
Person 1: Yes, that's another great aspect of the series. It's not just about the conflicts between different species, but also about the internal struggles within humanity. And it's all tied together by the overarching plot of the Reaper invasion.
Person 2: Definitely. The series does a great job of balancing the personal stories with the larger arc, so that every mission feels important and contributes to the overall narrative.
Person 1: And the series is also great at building up tension and suspense. The slow burn of the Reaper threat and the mystery of their origins kept me on the edge of my seat throughout the series.
Person 2: Yes, the series is really good at building up anticipation and delivering satisfying payoffs. Whether it's the resolution of a character arc or the climax of a game-long plotline, Mass Effect always delivers.
Person 1: Agreed. It's just such a well-crafted and satisfying series, with so many memorable moments and characters. I'm really glad we got to talk about it today.
Person 2: Me too. It's always great to geek out about Mass Effect with someone who appreciates it as much as I do!
Person 1: Yeah, it's always fun to discuss our favorite moments and characters from the series. And there are so many great moments to choose from!
Person 2: Definitely. I think one of the most memorable moments for me was the final conversation with your love interest before the final battle in Mass Effect 3. It was such a poignant and emotional moment, and it really showed how far the characters had come.
Person 1: Yes, that was a really powerful scene. It was great to see these characters find a quiet moment of connection before the end. And it was a great way to reward the player's investment in them.
Person 2: Another memorable moment for me was the speech that Shepard gives on the comms before the assault on the Collector Base. It's such an iconic moment in the series, and it really encapsulates the themes of the story.
Person 1: Yes, that speech is definitely one of the highlights of the series. It's so well-written and well-delivered, and it really captures the sense of hope and defiance that the series is all about.
Person 2: And speaking of great speeches, what did you think of Sovereign's speech on Virmire?
Person 1: Oh man, that speech gives me chills every time I hear it. It's such a powerful moment, and it really shows the scale and horror of the Reaper threat for the first time.
Person 2: Yes, that speech is definitely a standout moment for the series' lore. And it's just one example of the great writing and world-building in the games.
Person 1: Absolutely. It's a testament to the talent of the writers and actors that they were able to create such rich and complex characters with so much depth and nuance.
Person 2: And it's not just the main characters that are well-developed, but also the supporting characters like Anderson, Hackett, and Aria T'Loak. They all have their own stories and motivations, and they all contribute to the larger narrative in meaningful ways.
Person 1: Definitely. Mass Effect is just such a well-rounded and satisfying series in every way. It's no wonder that it's still beloved by fans all these years later.
Person 2: Agreed. It's a series that has stood the test of time, and it will always hold a special place in my heart as one of my favorite gaming series of all time.
Person 1: One of the most interesting ethical dilemmas presented in Mass Effect is the Krogan Genophage. What do you think about that storyline?
Person 2: Yeah, it's definitely a difficult issue to grapple with. On the one hand, the Krogan were portrayed as a threat to galactic stability, but on the other hand, the Genophage was a brutal and genocidal act.
Person 1: Exactly. I think one of the strengths of the series is its willingness to explore complex ethical issues like this. It's not just about good guys versus bad guys, but about the shades of grey in between.
Person 2: Yeah, and it raises interesting questions about ends justifying the means. The Salarians and Turians believed they were saving the galaxy, but they did so by sterilizing an entire species. But at the same time, there were also political and historical factors at play that contributed to the conflict.
Person 1: And it's not just about the actions of the governments, but also about the actions of individual characters. Mordin, for example, was initially portrayed as someone who believed in his work, but as the series progressed, we saw how his choices and actions weighed on his conscience.
Person 2: Yes, and that raises interesting questions about personal responsibility and atonement. Can an individual be held responsible for following orders, and can they ever truly make up for past mistakes?
Person 1: That's a really good point. And it's also interesting to consider the role of hope and leadership in situations like this. Characters like Wrex and Eve showed a path forward for the Krogan people, while others were more focused on revenge and hatred.
Person 2: Yeah, and that raises the question of whether a culture can change, or whether it's doomed to repeat the mistakes of its past.
Person 1: Definitely. And it's also worth considering the role of trust and forgiveness. Curing the Genophage required the Krogan to trust the other races again, but it was a difficult and painful process that required a lot of sacrifice.
Person 2: Yes, and that raises the question of whether forgiveness is always possible or appropriate in situations of oppression and injustice. Can the victims of such an act ever truly forgive their oppressors, or is that too much to ask?
Person 1: It's a tough question to answer. I think the series presents a hopeful message in the end, with characters like Mordin and Wrex finding a measure of redemption and reconciliation. But it's also clear that the scars of the conflict run deep.
Person 2: Yeah, that's a good point. Ultimately, I think the series' treatment of the Genophage raises more questions than it answers, which is a testament to its complexity and nuance. It's a difficult issue to grapple with, but one that's worth exploring.
Person 1: Let's switch gears a bit and talk about the character of Kasumi Goto. What did you think about her role in the series?
Person 2: I thought Kasumi Goto was a really interesting character. She was a master thief with a cool personality, but she also had a surprisingly emotional and tragic backstory.
Person 1: Yeah, I agree. I think she added a lot of style to the series and was a great foil to more serious characters.
Person 2: And I also appreciated the way the series handled her loyalty mission. It was clear that she was dealing with immense grief, but the mission never made it too melodramatic or over-the-top.
Person 1: That's a good point. I think the series did a good job of balancing the personal drama with the larger sci-fi elements. And it was refreshing to see a female character who was so skilled and independent.
Person 2: Definitely. I think Kasumi Goto was a great example of a well-written and well-rounded female character. She wasn't just there to be eye candy or a love interest, but had her own story and agency.
Person 1: However, I did feel like the series could have done more with her character. She was introduced as DLC, and didn't have as much screen time as some of the other characters.
Person 2: That's true. I think the series had a lot of characters to juggle, and sometimes that meant DLC characters got sidelined or didn't get as much integration as they deserved.
Person 1: And I also thought that her storyline could have been developed a bit more in Mass Effect 3. She had a nice moment in her side quest, but it felt like there was more to explore.
Person 2: I can see where you're coming from, but I also appreciated the way the series didn't overstay its welcome with her story. It was a short, poignant tale about memory and letting go, and it worked well.
Person 1: I can see that perspective as well. Overall, I think Kasumi Goto was a great addition to the series and added a lot of value to the game. It's a shame we didn't get to see more of her.
Person 2: Agreed. But at least the series was able to give her a satisfying arc and resolution in the end. And that's a testament to the series' strength as a whole.
Person 1: One thing that really stands out about Mass Effect is the quality of the sound design. What did you think about the series' use of music and audio effects?
Person 2: I thought the sound design in Mass Effect was really impressive, especially for a game that came out in the 2000s. The use of synthesizers to create the score and sci-fi elements was really iconic.
Person 1: Yes, I was really blown away by the level of detail and atmosphere in the audio. The weapon sounds were so punchy and futuristic, and the ambient sounds on different planets were really intense and exciting.
Person 2: And I also appreciated the way the series integrated the music with the story. It never felt like the music was just in the background, but was actively enhancing the characters or the story.
Person 1: Absolutely. The series had a great balance of electronic and orchestral music, which helped to ground the sci-fi elements in a more tangible and emotional world.
Person 2: And it's also worth noting the way the series' use of music evolved over its run. The score in the first game was very retro and synth-heavy, but by the end of the series, it had really refined and perfected the blend of styles.
Person 1: Yes, I agree. And it's impressive how they were able to accomplish all of this with a consistent vision. The fact that the series was able to create such a rich and immersive sci-fi universe with its sound is a testament to the talent and creativity of the audio team.
Person 2: Definitely. And it's one of the reasons why the series has aged so well. Even today, the sound design still holds up and sounds impressive, which is a rarity for a series that's over a decade old.
Person 1: Agreed. And it's also worth noting the way the series' use of music influenced other sci-fi games that came after it. Mass Effect really set the bar for what was possible in terms of sci-fi sound design in gaming.
Person 2: Yes, it definitely had a big impact on the genre as a whole. And it's a great example of how innovative and groundbreaking sci-fi can be when it's done right.
Person 1: Another character I wanted to discuss is Javik. What did you think of his character?
Person 2: Javik was a really unique and memorable character. He was cynical and harsh, but also had a lot of depth and a tragic past.
Person 1: Yes, I thought he was a great addition to the series. He added some much-needed conflict, but also had some important moments of character development.
Person 2: And I appreciated the way the series used him as a sort of living historical document, with his knowledge of the Protheans being instrumental in the resolution of some of the series' major storylines.
Person 1: Definitely. It was a great way to integrate a seemingly one-note character into the larger narrative. And it was also interesting to see the different perspectives he brought to the crew.
Person 2: Yeah, that was a clever storytelling device that really added to the sci-fi elements of the series. And it was also a great showcase for actor Ike Amadi, who played the character with so much gravity and energy.
Person 1: I also thought that Javik was a great example of the series' commitment to creating memorable and unique characters. Even characters that were added as DLC, like Javik or Aria, were given distinct personalities and backstories.
Person 2: Yes, that's a good point. Mass Effect was really great at creating a diverse and interesting cast of characters, with each one feeling like a fully-realized and distinct individual.
Person 1: And Javik was just one example of that. He was a small but important part of the series' legacy, and he's still remembered fondly by fans today.
Person 2: Definitely. I think his character is a great example of the series' ability to balance humor and tragedy, and to create memorable and beloved characters that fans will cherish for years to come.
"""

lines = conversation.split('\n')

for i in range(len(lines)):
  if lines[i].startswith('Person 1: '):
    grg_message(dynamodb,(now + timedelta(minutes=i)).isoformat(),lines[i].replace('Person 1: ', ''))
  elif lines[i].startswith('Person 2: '):
    grigoryev_message(dynamodb,(now + timedelta(minutes=i)).isoformat(),lines[i].replace('Person 2: ', ''))